<!--
*** Thanks for checking out this README Template. If you have a suggestion that would
*** make this better, please fork the repo and create a pull request or simply open
*** an issue with the tag "enhancement".
*** Thanks again! Now go create something AMAZING! :D
-->





<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]



<!-- PROJECT LOGO -->
<br />
<p align="center">
  <!--a href="https://github.com/rlxos/rlx-init.git">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a-->

  <h3 align="center">rlx-init</h3>

  <p align="center">
    A minimal and efficient initial ramdisk managment tool for rlxos
    <br />
    <a href="https://github.com/rlxos/rlx-init"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/rlxos/rlx-init">View Demo</a>
    ·
    <a href="https://github.com/rlxos/rlx-init/issues">Report Bug</a>
    ·
    <a href="https://github.com/rlxos/rlx-init/issues">Request Feature</a>
  </p>
</p>



<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Usage](#usage)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)
* [Acknowledgements](#acknowledgements)



<!-- GETTING STARTED -->
## Getting Started
initramfs is a root filesystem that load at an early boot stage. rlx-init provide early userspace to do tasks such as 
* Loading essential modules
* Mounting root filesystem
* Decrypting root partition
* Providing rescue shell

### Prerequisites

rlx-init is pre installed in [rlxos](https://releax.in/) but can be installed in any unix/linux system with following libraries and utilities avaliable:
* bash
* cat dd killall ls mkdir mknode mount umount sed sleep ln rm uname readlink basename
* modprobe kmod insmod lsmod blkid switch_root
* mdadm mdmom losetup touch install
* lvm cryptsetup findfs
* lvchange lvrename lvextend lvcreate lvscan
* udevd udevadm


#### Kernel configuration
kernel need to configured to support initial ram filesystem and ramdisk support

```
CONFIG_BLK_DEV_INITRD=y
```

```
General setup  --->
    [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
```

### Installation
``` bash
    DESTDIR='/' PREFIX='usr' sudo bash install.sh
```

<!-- USAGE EXAMPLES -->
## Usage
rlx-init use common and standard command line arguments for performing operations, like

```bash
    rlx-init 0.1.0 : initial ramdisk managment tool

    Usage: rlx-init [options]

    Options:
        --kernel=<version>              To use <version> of kernel for modules
        --out=<aout>                    save initramfs to <aout>
        --init=<path/to/init>           pack initramfs with custom init
        --binary='list of bins'         pack specified binaries in initramfs
        --modules='list of modules'     pack specified modules in initramfs
```

_For more examples, please refer to the [Documentation](https://github.com/rlxos/rlx-init/docs/rlx-init.html)_



<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/rlxos/rlx-init/issues) for a list of proposed features (and known issues).



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b 0.1.0`)
3. Commit your Changes (`git commit -m '[my-id] my awesome Feature'`)
4. Push to the Branch (`git push origin 0.1.0`)
5. Open a Pull Request



<!-- LICENSE -->
## License

Distributed under the GPL3 License. See `license` for more information.



<!-- CONTACT -->
## Contact
Manjeet Singh - [@releaxos](https://twitter.com/releaxos) - itsmanjeet@releax.in

[Join](https://discord.gg/TXTxDTYcdg) our discord server for any query


Project Link: [https://github.com/rlxos/rlx-init](https://github.com/rlxos/rlx-init)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements
* [Gentoo Custom initramfs](https://wiki.gentoo.org/wiki/Custom_Initramfs)





<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/rlxos/rlx-init.svg?style=flat-square
[contributors-url]: https://github.com/rlxos/rlx-init/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/rlxos/rlx-init.svg?style=flat-square
[forks-url]: https://github.com/rlxos/rlx-init/network/members
[stars-shield]: https://img.shields.io/github/stars/rlxos/rlx-init.svg?style=flat-square
[stars-url]: https://github.com/rlxos/rlx-init/stargazers
[issues-shield]: https://img.shields.io/github/issues/rlxos/rlx-init.svg?style=flat-square
[issues-url]: https://github.com/rlxos/rlx-init/issues
[license-shield]: https://img.shields.io/github/license/rlxos/rlx-init.svg?style=flat-square
[license-url]: https://github.com/rlxos/rlx-init/blob/master/license
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=flat-square&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/releax