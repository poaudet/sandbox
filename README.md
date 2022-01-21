# SANDBOX
This repository purspose is to store some helper scripts and other stuff for developping and testing.
All stable scripts are store either in the stable folder or in a new repository.

## Docker

Simple docker-compose to deploy docker inside a container.
Useful to test new image or your deployment script!

## Stable scripts
### copy_docker_to_host

Copy docker volume to a host folder.

<details><summary>Usage</summary>
<p>

```ShellSession
$ sh copy_docker_to_host name_of_container /path/you/want/to/copy /path/to/destination/on/host
```
</p>
</details>

### hass_start

I had problem with dimond module installation on my Home Assistant (Hass) container and I didn't wanted to build a custom image which I would have needed to rebuild for each version.

So! I've made a script and add it to my Hass Automation task.

<details><summary>Setup Hass</summary>
<p>

1. Put the script in a folder that you will bind with your container (i.e.: /config)

2. Deploy [Home Assistant Image](https://github.com/home-assistant/docker)

3. Add this line in the **configuration.yaml**
```yaml
shell_command:
  check_dimond: "sh hass_start.sh"
```

4. Add an automation in Hass to run on server start to run the script

</p>
</details>

### commit_cleaner

Copy docker volume to a host folder.

Thank you to [muhammad-numan](https://stackoverflow.com/users/8079868/muhammad-numan) for the answer on [StackOverflow](https://stackoverflow.com/questions/9683279/make-the-current-commit-the-only-initial-commit-in-a-git-repository)


<details><summary>Usage</summary>
<p>

1. Put the script in your local repository

2. (Optional) Add the script in your **.gitignor**
```ShellSession
$ echo "commit_cleaner.sh" > .gitignore
```

3. Run the script
```ShellSession
$ sh commit_cleaner.sh branch commit_message
```