# docli

docli is a small docker cli helper for common tasks.

## Installation

A pre-built binary for macos exists under bin/. Simply copy this to a folder in your PATH to have access to it wherever. See "Building the binary" if you want to build the code yourself or need to build it for a different architecture.

If you have the go runtime installed on your system, you can also build and add the binary to your path cd:in into the src folder and running
```
go install docli.go
```

This should build the binary and add it to ```$GOPATH```, and provided ```$GOPATH``` is in your system path the command should now be available throughout your system.



## Features

### Open terminal to currently running container

This basically runs ```docker exec -ti <CONTAINER_ID> <SHELL>```, but with the benefit of outputting a list of currently running containers and shell options to choose from. Currently only supporting containers running ```bash``` or ```sh```, as these seem to be the two most common shells used in docker images.


## Building the binary

To build the project into a binary, run
```
go build -o bin/docli docli.go
```

Note that this would only compile the binary for the OS that the command is executed on. You'll need to use golang build arguments to build for other architectures.
