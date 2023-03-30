# InLab Container Stacks

> Wanna run InLab projects without the hass of setting up environments? This is for you!

## Features

- CoFI installed ✅
- Espresso installed ✅
- CoFI examples ready to run ✅

## Getting Started

### Pull & run (Recommended)

This hasn't been available yet, but will be available very soon!

<!-- ```console
$ docker run -p 8888:8888 inlab/inlab:latest
```

Then open the Juptyer Lab with your browswer at: `https://127.0.0.1:8888`. Enter the token as shown in the terminal into your browser when prompted. -->

### Build your own (Optional)

```console
$ docker build --file image/Containerfile --tag inlab .
$ docker run -p 8888:8888 inlab
```

The Jupyter Lab should then be accessible through your browser locally.

## More references

The InLab containers are built based on the Jupyter Docker Stacks, and we inherit the 
entry point created by the Jupyter team. 

If you have any further questions about running
the containers, we kindly recommend referring to the
[Getting started guide](https://github.com/jupyter/docker-stacks/tree/main#quick-start)
provided by the Jupyter team.

## Acknowledgement

This infrastructure is genereated by the 
[Jupyter Docker Stacks cookiecutter](https://github.com/jupyter/cookiecutter-docker-stacks).
