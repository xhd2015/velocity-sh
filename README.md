# About
The velocity-sh project is designed to use Apache Velocity in bash scripts.

Currently tested script enviornment is cygwin.

# Get Started
- Fundamental usage,read template from stdin:
```bash
$ echo 'Hello $NAME'|java -jar velocity-templatee.jar template - NAME=world
Hello world
```
- Use template file:
```bash
$ cat demo.vm
Hello $NAME
$ java -jar velocity-templatee.jar template demo.vm NAME=world
Hello world
```
- View help
```bash
$ java -jar velocity-templatee.jar help
```

# Examples
The following examples shows utilities provided by this project

- exec, execute external shell command 
```vtl
$ShellUtils.exec('bash.exe','-c','echo Hello world')
errno=$ShellUtils.errno()
```

- Provide extra functionality by setting `import.class.list` to a comma separated tools
```vtl
$CustomTool.customMethod(...)
```
invoking script, ensure `com.example.your.custom.CustomTools` is present on CLASSPATH:
```bash
java -Dimport.class.list=CustomTools:com.example.your.custom.CustomTools -jar velocity-templatee.jar template template.vm 
```

# Advanced shell scripts wrapper
All wrappers are under [src/main/resources/sh](src/main/resources/sh),
 - [mktemplate.sh](src/main/resources/sh/mktemplate.sh)  a fast way to invoke velocity-templatee
 
 - [aggregate-file.sh](src/main/resources/sh/aggregate-file.sh)  a flexible way to aggregate files for edit and restore back later

