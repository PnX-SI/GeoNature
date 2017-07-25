# Install Docker CE avec Debian:
## Install from a package (recommended)
 1. Go to https://download.docker.com/linux/debian/dists/, choose your Debian version
 2. Install Docker CE, changing the path below to the path where you downloaded the Docker package.
	```bash sudo dpkg -i /path/to/package.deb ```
 3. Verify that Docker CE is installed correctly by running the hello-world image.
	```bash sudo docker run hello-world ```
 That's it! :tada: :sparkles: :sparkles:
# Install Docker Compose:
  https://docs.docker.com/compose/install/