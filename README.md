# talend-aws-baseline

These scripts work together with the Talend Unattended Installer (TUI) and Talend AWS Cloud Formation templates
to install Talend on EC2 instances.

### Cloud Formation Templates

The Cloud Formation templates populate dependencies, e.g. database hostnames, ports, etc, into shell scripts
which are used to populate OS environment environment variables.  These shell scripts are sourced prior to
running the installer.  The  environment values are imported by the installer configuration files to
initialize configuration values which are in turn used by the TUI installer.

### TUI

TUI is a groovy application for installing Talend components.  It is data driven using Groovy configuration
files.  These Groovy scripts are similar to, but much more powerful than java property files.  They also
support interpreating environment variables.

There are many other configuration settings which may be customized but which are not passed via the Cloud
Formation templates.  These settings can be manually tweaked in these configuration scripts themselves, or
entererd into a supporting setenv.sh file and then referenced like the other environment variables from the
configuration scripts.

### Referencing Environment Variables from Configuration Scripts

To reference environment variables from the Groovy configuration scripts, follow the Groovy syntax.

Declare a top level Groovy variable and initialize it to the system environment variables.  The
`env` variable below is a Map that is populated with environment values.  It is then used to initialize
the `root_dir` variable.

    def env = System.env()
    
    ...
    
    root_dir = env['TALEND_REPO']

### Environment Variables

The `setenv.sh` file will be created by the Cloud Formation scripts.  The sample provided here is for
test purposes.

**The setenv.sh file must be sourced rather than invoked as a child script.**

The `tui` installer must be run as `sudo`, so keep in mind to use the `-E` command flag to preserve the
environment. 

    source setenv.sh
    sudo -E ./install tac

The two commands above will initialize the environment and then invoke the tui installer.

### Merging Configuation Files with TUI

The files in the `tui` directory have been extracted from the TUI installer and modified to work in the
Talend AWS Quickstart environment.  They need to be merged with the TUI installer on each EC2 instance node.
This will be done the Cloud Formation templates.  For this reason the file and directory structure of the
`tui` directory mirror that of the TUI installation tool.

### Scripts

#### Udate Hosts

Amazon EC2 Linux instances cannot resolve their own private host names.  The `update_hosts.sh` script modifies
the `/etc/hosts` file and the `/etc/sysconfig/network` file with information from the AWS REST reflection API
to fix this situation.  This ensures that TUI can operate with all of the default values.

#### JRE Installer

For convenience, the TUI JRE installer has been extracted to the scripts directory so that it can be downloaded
by the Cloud Formation scripts and run directly.  The TUI JRE uses yum or apt-get to install Java.

An alternatve to the TUI installer is also provided.  The jre-installer.sh will install the JRE from a previously
downloaded tgz file.  This will typically be slightly faster, and it will make environment self-contained.
