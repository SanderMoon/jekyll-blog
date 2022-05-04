---
layout: single
title:  "Self-host a blog part 0: Setting up the infrastructure"
date:   2022-05-03 19:48:05 +0000
categories: Technical
toc: true
header:
  teaser: /assets/images/raspberrypi-teaser.png
---

Welcome to my series about self-hosting a blog!
There are many different topic we will need to cover in order to self host anything...

To name a few:
- Hardware
- Operating systems
- Domains
- Networking
- System administration
- Secure connections
- Packaging software
- Deployment
- ...

In this series I will explain step-by-step how to manage all of these things. 

Footnote: the way I host my website is rather over-engineered, thus there are many easier and probably cheaper alternatives for hosting a website. I wanted to expand my knowledge on certain tooling so I used them as the foundation for my journey. The result? A highly available blog that is secure, responsive and has (near) zero-downtime, and a platform that can be used for many different software projects.

Here is an incomplete list of tooling and hardware used for this project:
- Raspberry Pi 4 4GB: a computer
- Microk8s: a Kuebernetes
- Jekyll: a static website generator
- ArgoCD: a continuous deployment controller
- GitHub actions: A Git workflow manager

Still interested? Then keep reading!

## Let's talk hardware
In order to run anything, you need a server. A server means hardware. Hardware means a shopping list, and a shopping list means making expenses. 

Expenses to look out for:
- Initial cost
- Power consumption 

Some other things that you should keep in mind when purchasing hardware:
- Computing power requirements
- Memory requirements
- Processor architecture
- Options for redundancy
- Noise levels
- Form factor
- Ease of installation

### Single-board Computers
As we're hosting a static blogging website we don't need the most sofisticated hardware. Currently tiny single-board computers like Raspberry Pi have more than enough computation power and memory to do the job. They are small, quiet and power efficient and really inexpensive compared to a full-blown server, so let's take three of them.

Having multiple Raspberry Pi's is handy as it allows for compute redundancy. If one of them fails, the others can take over. Redundancy is a requirement for a highly available platform. 

Depending on your needs and budget, you can also choose to use a single Raspberry Pi for hosting. However, if the board, the SD card or the power fails, your website will be down and it will take some time to recover. 

### Downsides
There are downsides to using a Raspberry Pi for hosting software. The main one is that our chosen Raspberry Pi has an ARM64 CPU architecture, which basically means that it differs from more commonly used architectures like AMD64 or x86-64. This means that common software packages are often not officially supported out of the box and requires some tweaking to get it working, if possible at all. You'll see further in this series that we need to tweak quite some things to make it all work. 

## The shopping list
So we've decided to use one or multiple Raspberry Pi's as our computer. What else do we need? And what does it cost?

| **Amount** | **Item**                                                                                                                          | **Description**                  | **Total Price (EUR)** |
|------------|-----------------------------------------------------------------------------------------------------------------------------------|----------------------------------|-----------------------|
| 3x         | [Raspberry Pi 4 4GB](https://tweakers.net/pricewatch/1414470/raspberry-pi-4-model-b-4gb-ram.html)                                 | Your single-board computers      |                180.00 |
| 3x         | [MicroSDXC card w/ adapter(128 GB)](https://tweakers.net/pricewatch/1741912/samsung-evo-plus-microsd-card-2021-128gb.html)        | Internal storage                 |                 38.00 |
| 3x         | [USB A to USB C cable (0.5m)](https://www.allekabels.nl/usb-c-kabel/11518/2259588/usb-c-naar-usb-a-kabel-20.html)                 | Power cables                     |                 24.00 |
| 3x         | [Network cable (0.25m)](https://www.allekabels.nl/cat5e-kabel/15545/1280381/cat-5e-uutp-netwerkkabel.html)                        | Pi to network switch             |                  2.70 |
| 2x         | [RPi cluster rack](https://www.kiwi-electronics.nl/nl/stapelbare-behuizing-met-ventilator-voor-raspberry-pi-9974)                 | x2 so we can mount all boards    |                  26.0 |
| 1x         | [Network cable (1.5m)](https://www.allekabels.nl/cat5e-kabel/15545/1280381/cat-5e-uutp-netwerkkabel.html)                         | Switch to Router                 |                  1.50 |
| 1x         | [Power Strip with USB ports](https://www.allekabels.nl/stekkerdoos/7069/3877776/5-voudige-stekkerdoos-met-3-usb-poorten-wit.html) | Number of sockets of your choice |                 25.00 |
| 1x         | [Network Switch](https://www.coolblue.nl/product/536278/tp-link-tl-sg105e.html)                                                   | Gigabit                          |                 25.00 |
|            | **TOTAL**                                                                                                                         |                                  |            **322.20** |

Above you can see the complete shopping list that I used to create my whole set-up. You may adjust to your needs. You can also save some money by using some cables or hardware that you have laying around at home. 

## Laying the foundation

After all of your packages arive we can start building!

**Images coming soon**

## Installing the OS

In order to finish our server set-up we need an OS.
Choice of OS is often quite personal and as I did not have a lot of experience with linux when i started this project, I decided to go with Ubuntu Server 21.04. There is a [neat little guide](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi) on the Ubuntu website on how to set it up on your Raspberry Pi. You just have to do this for each of your Raspberry Pi's and we should be good to go!

Some assumptions before installing the OS:
- I'm using ethernet cables and a network switch to directly connect to our router. So no WiFi!
- We connect remotely with SSH, like defined in the [Ubuntu guide](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#4-boot-ubuntu-server)

## Reserving an IP address for your Raspberry Pi boards.
The IP addresses of the devices in your home network are prone to change when the configuration of your router changes or your router is reset. As we will frequently want to access our Raspberry Pi's and also let them communicate with each other, we will need a stable IP address and thus need to reserve an IP address in your home network. Every router comes with a DHCP server that allows you to do this. 

### Finding your router's IP
You'll have to log in to your router, which requires finding your router's IP address. 
[This guide](https://www.expressvpn.com/what-is-my-ip/router-ip) should be able to help you.

### Finding the MAC address of your Pi
The second thing you need is the MAC-address of your Raspberry Pi board. This should be in the same windows (ipconfig) where you found the IP address of your Raspberry Pi, outlined in the Ubuntu guide. 

### Create a reservation
Each router differs, so it's hard to go in depth on this part but it should look somewhat like this:

Now:
1. Log in to your router
2. Go to DHCP setting
3. Add Reservation
4. Put in the IP address
5. Put in the MAC address
6. Save the reservation
7. Restart the router if needed

Most router brands have guides available on how to do this.

## Conclusion
You should now have three separate single-board computers running!

In the next blog we will set up Kubernetes on these boards, so we can actually combine them into a highly available cluster. 


