---
layout: single
title:  "Self-host a blog part 0: The Plan"
date:   2022-05-03 19:48:05 +0000
categories: Technical
toc: true
header:
  teaser: /assets/images/CICD-flow.PNG
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

The way I host my website is rather over-engineered and definitely not all perfect, so there are easier and probably cheaper alternatives for hosting a website if that's the only goal in mind. I wanted to expand my knowledge on certain tooling so I used them as the foundation for my journey. The result? A highly available blog that is secure, responsive and has (near) zero-downtime, and a platform that can be used for many different software projects.

**Note: this first post is very technical and mostly intended for more experienced readers who would like a quick overview. It is not expected from the reader to understand all technologies and terms used in this post, as they will be explained in the rest of the series.**

## Choosing a Web Development Framework
When creating a website as a hobby project, there are a number of factors that can be important for choosing a technology stack. Like:
- Your current skillset and your ambitions
- Your use-case
- Required functionalities
- Amount of available time

I'm expecting my audience to consists mostly out of hobbyists or beginner level (web)developers. Creating a website can seem a daunting task if you have no or little web-developement knowledge. That's because it kind of is, especially if you want to dedicate your free time to setting up your website. Out of experience I can say that the more ambitious you start your project planning, the less likely it will be that you will ever finish it. My advise is: keep your project very simple at the start!

### Jekyll
As a back-end developer with no ambitions to learn a ton about front-end, I looked for a framework that is easy to set up, that requires minimal web-development experience and that makes writing blogs relatively easy. I've found these point in the framework [Jekyll](https://jekyllrb.com/). 

The upsides of Jekyll:
- You write blogposts in Markdown
- No Javascript, CSS and Ruby knowledge required
- No database
- Easy to set up
- Lightweight
- Simple

Downsides of Jekyll:
- Every change or addition of a blogpost requires a redeployment of the whole website because it is [stateless](https://www.redhat.com/en/topics/cloud-native-apps/stateful-vs-stateless)
- Adding pictures is rather [inconvenient](https://jekyllrb.com/docs/posts/#including-images-and-resources)


It's a perfect framework for writing technical blogs, but it's not really suited for any other purposes. If you're more interested in general-purpose bogs, you could check out [Wordpess](https://wordpress.com/nl/) and check out some blogpost if you want to [self-host](https://projects.raspberrypi.org/en/projects/lamp-web-server-with-wordpress) it. 

Note: If you already have experience with web-application there are many other frameworks that can help you create an awesome website. I chose Jekyll because it's good at what it does, and will save me some time researching how to properly utilize fancy javascript frameworks. 

## Hardware and infrastructure
In order to run your website you will need hardware. Because I want full control over my website and want to learn the end-to-end process of hosting a website, I will host my own website, on my own hardware. If you don't want to deal with hardware, networking and infrastructure you can use Webhosting services like [DigitalOcean](https://www.digitalocean.com). I've written this blog purely for people who are itnerested in hosting their own website, so you might want to stop reading if you like to use webhosting providers. 

### The hardware
For this project I use three Raspberry Pi micro computers as the hardware for my website. In my next blogpost I explain the decision on why three of these boards and I will share the shopping list that is used. There I will also explain how I set these up. A Raspberry Pi is perfect for a project like this. They are cheap, small and efficient. They are not the fastest, but can easily host our website. 

### Infrastructure management
When hosting your own website, managing infrastructure will be an important topic to cover. You'll be responsible for everything regarding your website. Hardware failures, security, unexpected software failures, IP routing are all part of the deal when self-hosting, which can give you a headache if you don't think this through. There will be a seperate blog post that will go in-depth into the infrastructure set-up regarding the software used and networking.

I've decided to use [Kubernetes](https://kubernetes.io/) as an orchestrator for all my infrastructure. Kubernetes is an open-source system for automating deployment, scaling, and management of containerized applications. If this is all magic to you, don't worry, it will all be explained in my blogs, so stay tuned! 

As our hardware is quite limited on the memory and cpu, we use a light-weight implementation of Kubernetes called [Microk8s](https://microk8s.io/). Microk8s also supports the creation of a [multi-node cluster](https://microk8s.io/docs/high-availability) across your RPi boards, which means that your RPi's work together to manage the website! This means that if one of the boards fail, the others can take over. This makes for a very robust system for minimal downtime applications. And best of all; once it is set-up you can host other applications next to your website as well.

### Build and Deployment Philosophy
When you are making changes to your website, you want it to reflect on your website. But how do we get these changes to our hardware? As you don't want any downtime or hassle with manual file transfer and deployments we are implementing the principles of [CI/CD](https://en.wikipedia.org/wiki/CI/CD).

We set up a [Github repository](https://github.com/SanderMoon/jekyll-blog) to host our source code. Whenever you make changes to your website, you push the code to the repository. Because we are using Kubernetes, we need to create a docker image out of our code, together with a webserver, so that eventually we can host it in our RPi cluster. This means we need to build our application into a docker image and send it to [Dockerhub](https://hub.docker.com/repository/docker/smoonemans/jekyll-blog). To do this we can apply the strategy of [Continuous Integration]() by creating a build pipeline in [GitHub Actions](https://github.com/SanderMoon/jekyll-blog/blob/master/.github/workflows/docker-image.yml). This will automatically, on a new push, build your docker image and push it to DockerHub. 

Now we just need to get the docker image in our RPi cluster. We can apply the strategy of Continuous Delivery by pulling the new docker image to the cluster when changes are detected. A great tool for Kubernetes that manages this automatically is ArgoCD. ArgoCD sits in your cluster and waits for changes to your infrastructure. If any changes arise, it will pull the new information and apply it directly to your cluster and manages it so that you don't have any downtime. 

we will have a seperate [Github repository](https://github.com/SanderMoon/jekyll-kubernetes-infra) for infrastructure management. You can manage the desired infrastructure state in Kubernetes by creating manifest files for your resources. ArgoCD will monitor this repository for changes while our GitHub Actions pipeline updates the docker image tags of our website resource. 

This gives us an end-to-end CI/CD pipeline for our website!
Below is an illustration of the full flow, which should make it easier to understand. 

![alt]({{ site.url }}{{ site.baseurl }}/assets/images/CICD-flow.PNG)

## Architecture
The below image shows all the different components needed for traffic to flow from someones computer to your website:
![alt]({{ site.url }}{{ site.baseurl }}/assets/images/traffic-flow.PNG)

Topics of future blogs:
1. [Setting up the hardware](({{ site.url }}{{ site.baseurl }}/technical/self-hosting-a-blog-part-1/))
2. Setting up a highly available cluster in Microk8s
3. Setting up a Jekyll website and manually deploy it to the cluster
4. Registering your domain name and routing traffic to your cluster
5. Creating your repositories and setting up GitHub Actions
6. [Installing and setting up ArgoCD on your Microk8s cluster]({{ site.url }}{{ site.baseurl }}/technical/installing-argocd/)
7. Making your website traffic secure with Kubernetes Cert manager and Let's Encrypt

