package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"syscall"

	"github.com/AlecAivazis/survey/v2"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/client"
)

var cli *client.Client
var Running []types.Container

func main() {

	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		log.Fatal(err)
	}

	containers, err := cli.ContainerList(context.Background(), types.ContainerListOptions{})
	if err != nil {
		log.Fatal(err)
	}

	if len(containers) == 0 {
		fmt.Println("No running containers found")
		os.Exit(0)
	}

	var runningContainers []string = []string{}

	for _, container := range containers {
		runningContainers = append(runningContainers, fmt.Sprintf("%s %s", container.ID[:10], container.Image))
	}

	// the questions to ask
	var qs = []*survey.Question{
		{
			Name: "selectedContainer",
			Prompt: &survey.Select{
				Message: "Choose running container to bash into:",
				Options: runningContainers,
			},
		},
		{
			Name: "shell",
			Prompt: &survey.Select{
				Message: "Choose a container shell:",
				Options: []string{"bash", "sh"},
				Default: "bash",
			},
		},
	}

	// var selectedContainer survey.OptionAnswer

	// the answers will be written to this struct
	answers := struct {
		SelectedContainer survey.OptionAnswer // survey will match the question and field names
		Shell             string
	}{}

	// prompt := &survey.Select{
	// 	Message: "Choose running container to bash into:",
	// 	Options: runningContainers,
	// }
	// err = survey.AskOne(prompt, &selectedContainer)
	err = survey.Ask(qs, &answers)

	if err != nil {
		log.Fatal(err)
	}

	targetContainer := containers[answers.SelectedContainer.Index]

	fmt.Printf("Selected container %s \n", targetContainer.ID[:10])

	execPath, err := exec.LookPath("docker")
	if err != nil {
		log.Fatal(err)
	}

	err = syscall.Exec(execPath, []string{"", "exec", "-ti", targetContainer.ID, answers.Shell}, os.Environ())
	if err != nil {
		log.Fatal(err)
	}
}
