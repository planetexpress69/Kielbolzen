# Kielbolzen

This is an example for a menulet that asks for some stuff via HTTP and displays a status based on the server's response.
It's for educational purposes only. Beware of the poor error handling!

## Install
n/a

## Getting Started
* Just run the target
* **Watch the icon in the upper rigtht corner!**

## How it works
Kielbolzen itself runs as a headless agent, so there's no main window and main menu at all.
After being started it polls a "sort of" webservice every 5 seconds. Since the response is encoded in XML, there's some parsing involved.
All heavy lifting is done by [MKNetworkKit](https://github.com/MugunthKumar/MKNetworkKit) and [XMLReader](https://github.com/amarcadet/XMLReader).

```
<?php
header ("Content-Type:text/xml");
$xml = '<?xml version="1.0" encoding="utf-8"?>
<payload>
<value>'.rand (0,4).'</value>
</payload>
';
echo $xml;
?>
```
![alt text](http://i.imgur.com/WWLYo.gif "Frustrated cat can't believe this is the 12th time he's clicked on an auto-linked README.md URL")