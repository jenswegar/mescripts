# mescripts
A bunch of egoistic scripts and cli aliases for easier computer life.

The scripts found here are mainly targeted for use in my own MacOS environment and to make my own life easier, so unless I feel motivated I won't be putting too much effort into ensuring they are cross-platform. Having said that, if you do happen to find any of the stuff in here useful and want to contribute some fixes I'm happy to accept pull requests :) Also, if you find a bug but don't know how to fix it yourself, feel free to leave a bug report and I'll try to have a look at it.


## Setup

Most scripts assume the ZSH shell on MacOS and oh-my-zsh (https://github.com/robbyrussell/oh-my-zsh) installed.

### Git
The ```git``` folder contains some customizations to git configurations.

### ZSH

Copy the content of the following files to the end of the ```.zshrc``` file:

* zsh/aliases
* zsh/named_directories

### GO

The ```go``` folder contains CLI tools written in golang. The ```bin``` folder contains a precompiled binary for the tool. Note that the binary is unsigned and isnt' notarized (don't want to spend the money for an Apple Developer license atm.). This means macOS will complain that it's from an unknown source and will refuse to run it. To allow it to run anyways, close the first dialog, then open ```Security & Privacy``` settings. There should be a notice at the bottom about macOS having blocked the binary. Click ```Allow anyway```, then run the binary again and click Open at the prompt. You should now be able to run the binary without problems. This will have to be repeated anytime the binary is updated.