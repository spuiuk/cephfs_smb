/*
A Sample program using the go-ceph bindings to create a Ceph-SMB cluster.

The sample program expects the following
- A Cephfs volume named "mycephfs" to be present in the cluster
- A subvolume group named "smbshares" to be present in the "mycephfs" volume
- The subvolume smbshares should have the directories "share1", "share2" and "share3" created within it.

To create Ceph-SMB resource
# go run -tags ceph_preview . create

To list existing Ceph-SMB resources
# go run -tags ceph_preview . describe

To clean up all Ceph-SMB resources created
# go run -tags ceph_preview . cleanup

The -tags ceph_preview flag is required to use the Generic Resource feature.
This is a new feature which is currently in preview stage for go-ceph.
*/
package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/ceph/go-ceph/common/admin/smb"
	"github.com/ceph/go-ceph/rados"
)

var err error

// The cluster name
var clusterName string = "smb-cluster-1"

// Helper function to initiate a connection to the ceph cluster
func connect() *rados.Conn {
	conn, err := rados.NewConn()
	if err != nil {
		log.Fatalf("failed to create new connection: %v", err)
	}

	err = conn.ReadDefaultConfigFile()
	if err != nil {
		log.Fatalf("failed to read default config file: %v", err)
	}

	err = conn.Connect()
	if err != nil {
		log.Fatalf("failed to connect to cluster: %v", err)
	}
	return conn
}

// Helper function to disconnect from a ceph cluster
func disconnect(c *rados.Conn) {
	c.Shutdown()
}

// Print out a data structure in json format.
func prettyPrint(r any) {
	j, _ := json.MarshalIndent(r, "", "    ")
	fmt.Println(string(j))
}

// The interface and error helper to get more detailed ceph-smb errors
type MGRError interface {
	Status() string
	Body() []byte
}

func printFancySMBError(err error) {
	var merr MGRError
	if errors.As(err, &merr) {
		// its one of them fancy mgr errors
		fmt.Printf("-----Fancy Error -----\n")
		fmt.Print("Error Status: %v", merr.Status())
		fmt.Printf("Error Response:\n%v\n", string(merr.Body()))
		fmt.Printf("----------------------\n")
		return
	}
	// just a plain old error
	fmt.Printf("Error: %w\n", err)
}

// Create Ceph-SMB resources
func create() {

	// New cluster creation
	cluster := smb.NewUserCluster(clusterName)
	cluster.Placement = smb.Placement{
		"label": "smb",
	}
	// Setting Custom Ports
	cluster.CustomPorts = smb.CustomPortsMap{
		smb.SMBService:        10445,
		smb.SMBMetricsService: 10009,
		smb.CTDBService:       10379,
	}

	// User and Group configuration
	usersGroups := smb.NewLinkedUsersAndGroups(cluster)
	users := []smb.UserInfo{
		{
			Name:     "user1",
			Password: "x",
		},
		{
			Name:     "user2",
			Password: "x",
		},
		{
			Name:     "user3",
			Password: "x",
		},
	}
	groups := []smb.GroupInfo{
		{
			Name: "group1",
		},
	}
	usersGroups.SetValues(users, groups)

	// Share 1: Public share with rw acccess for everyone.
	share1 := smb.NewShare(clusterName, "share1")
	share1.Name = "Share 1"
	share1.ReadOnly = false
	share1.Browseable = true
	share1.SetCephFS(
		"mycephfs",  // CephFS volume name
		"",          // subvolume group (empty for default)
		"smbshares", // subvolume (empty to use path)
		"/share1",   // path within the subvolume
	)

	// Share 2: Only users user1 & user2 have access to the share
	// For this share, we setup QoS using the Generic Resource structure
	share2 := smb.NewShare(clusterName, "share2")
	share2.Name = "Share 2"
	share2.ReadOnly = false
	share2.Browseable = true
	share2.SetCephFS(
		"mycephfs",  // CephFS volume name
		"",          // subvolume group (empty for default)
		"smbshares", // subvolume (empty to use path)
		"/share2",   // path within the subvolume
	)
	share2.RestrictAccess = true
	share2.LoginControl = []smb.ShareAccess{
		{
			Name:     "user1",
			Category: smb.UserAccess,
			Access:   smb.AdminAccess, // user1 is admin
		},
		{
			Name:     "user2",
			Category: smb.UserAccess,
			Access:   smb.ReadWriteAccess,
		},
	}
	// Set up QoS for share2
	// A Generic resource is used when the corresponding Concrete Resource
	// instances do not exist for the feature you require.
	// One such feature is QoS
	// We first get the Generic version of share2
	gshare2, err := smb.ToGeneric(share2)
	// For any further modifications to share2, use gshare2 for modifications
	// We add the new QoS values to the Generic Resource.
	gshare2.Values["cephfs"].(map[string]any)["qos"] = map[string]string{"write_ios_limit": "50", "write_bw_limit": "5M"}

	// Share 3: Only users in group group1 have access to the share
	share3 := smb.NewShare(clusterName, "share3")
	share3.Name = "Share 3"
	share3.ReadOnly = false
	share3.Browseable = true
	share3.SetCephFS(
		"mycephfs",  // CephFS volume name
		"",          // subvolume group (empty for default)
		"smbshares", // subvolume (empty to use path)
		"/share3",   // path within the subvolume
	)
	share3.RestrictAccess = true
	share3.LoginControl = []smb.ShareAccess{
		{
			Name:     "group1",
			Category: smb.GroupAccess,
			Access:   smb.ReadWriteAccess,
		},
	}

	resources := []smb.Resource{
		cluster,
		usersGroups,
		share1,
		gshare2, // We use the Generic version for share2
		share3,
	}
	err = smb.ValidateResources(resources)
	if err != nil {
		log.Fatalf("failed to validate resources: %v", err)
	}

	conn := connect()
	defer disconnect(conn)
	smbAdmin := smb.NewFromConn(conn)
	result, err := smbAdmin.Apply(resources, nil)
	if err != nil {
		fmt.Print("Result")
		prettyPrint(result)
		printFancySMBError(err)
		log.Fatalf("failed to apply resources: %v", err)
	}
}

func describe() {
	conn := connect()
	defer disconnect(conn)

	smbAdmin := smb.NewFromConn(conn)
	result, err := smbAdmin.Show(nil, nil)
	if err != nil {
		log.Fatalf("failed to call Show(): %v", err)
	}
	for _, res := range result {
		fmt.Printf("%v - %v\n", res.Type(), res.Identity())
	}
}

func cleanup() {
	conn := connect()
	defer disconnect(conn)

	smbAdmin := smb.NewFromConn(conn)

	// Call ceph smb show
	resources, err := smbAdmin.Show(nil, nil)
	if err != nil {
		log.Fatalf("failed to call Show(): %v", err)
	}

	nresources := []smb.Resource{}
	// For each resource returned, set IntentValue to removed
	for _, r := range resources {
		switch res := r.(type) {
		case *smb.Cluster:
			if res.ClusterID == clusterName {
				fmt.Printf("Deleting - %v - %v\n", r.Type(), r.Identity())
				res.IntentValue = "removed"
				nresources = append(nresources, r)
			}
		case *smb.Share:
			if res.ClusterID == clusterName {
				fmt.Printf("Deleting - %v - %v\n", r.Type(), r.Identity())
				res.IntentValue = "removed"
				nresources = append(nresources, r)
			}
		case *smb.JoinAuth:
			if res.LinkedToCluster == clusterName {
				fmt.Printf("Deleting - %v - %v\n", r.Type(), r.Identity())
				res.IntentValue = "removed"
				nresources = append(nresources, r)
			}
		case *smb.UsersAndGroups:
			if res.LinkedToCluster == clusterName {
				fmt.Printf("Deleting - %v - %v\n", r.Type(), r.Identity())
				res.IntentValue = "removed"
				nresources = append(nresources, r)
			}
		}
	}

	// Now Validate the resources
	err = smb.ValidateResources(nresources)
	if err != nil {
		log.Fatalf("failed to validate resources: %v", err)
	}

	// Apply the modified resources
	result, err := smbAdmin.Apply(nresources, nil)
	if err != nil {
		fmt.Print("Result")
		prettyPrint(result)
		printFancySMBError(err)
		log.Fatalf("failed to apply resources: %v", err)
	}

}

func print_usage(exec string) {
	fmt.Printf("Usage: simple_usergroup <create|cleanup|describe>\n")
}

func main() {
	args := os.Args

	if len(args) == 1 {
		print_usage(args[0])
		fmt.Printf("\nCalling with describe option:\n\n")
		describe()
		return
	}

	switch args[1] {
	case "create":
		create()
	case "cleanup":
		cleanup()
	case "describe":
		describe()
	}
}
