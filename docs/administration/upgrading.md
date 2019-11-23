---
title: Upgrading to a new release
---

# Preparing

The release page contains a changelog, and below it, upgrade instructions. **Read and understand** the release instructions.

Some tasks (like database migrations) can take a while, so we advise you to run commands inside a `tmux` or `screen`.

# Backup

Always make sure your database and `.env.production` file are properly backuped before performing upgrades.

Unless stated otherwise in the release notes, the following steps are enough to upgrade Mobilizon.

# Steps

### Fetch latest code
Switch to the `mobilizon` user:

```bash
sudo -i -u mobilizon
```

And navigate to the Mobilizon root directory:

```bash
cd /home/mobilizon/live
```

Fetch the latest tags
```bash
git fetch --tags
```

And checkout the tag you want to switch to. For instance, if I want to upgrade to version `v1.1`:
```bash
git checkout v1.1
```

### Fetch new dependencies
Fetch new and/or updated Elixir and NodeJS dependencies
```bash
mix deps.get
```
```bash
cd js
yarn install
```

### Rebuild Mobilizon's front-end
```bash
yarn run build
cd ../
```

### Recompile Mobilizon
```bash
mix compile
```
Let's switch back to your regular user.

### Stop running Mobilizon processes
```bash
sudo systemctl stop mobilizon
```

### Perform database migrations

Go back to the `mobilizon` user.
```bash
sudo -i -u mobilizon
cd live
mix ecto.migrate
```
### Restart Mobilizon
Let's switch back one last time to your regular user.
```bash
sudo systemctl restart mobilizon
```

You can follow the Mobilizon logs to check that everything works properly. 
```bash
sudo journalctl -u mobilizon -f
```

**That’s all!** You’re running the new version of Mobilizon now.

If you have issues after upgrading, try reviewing upgrade steps and release notes.
Then feel free to [contact us](../about.md#discuss) or file an issue on [our Gitlab](https://framagit.org/framasoft/mobilizon/issues)
