---
layout: single
title:  "Installing ArgoCD on Raspberry Pi 4 with microk8s"
date:   2022-01-13 13:30:05 +0100
categories: Technical
toc: true
---

Currently this website is running on my Raspberry Pi cluster at home.
The cluster consists of 3 Raspberry Pi 4 boards, running in a high availability (HA) configuration in Kubernetes.
I've used Microk8s as a Kubernetes distribution and wrote a [blogpost]() about setting that up previously.

In order to easily push changes to my cluster I needed a CI/CD pipeline of some sort.
I decided to use GitHub Actions for CI and ArgoCD for CD. 

In this blogpost I explain how to set up ArgoCD in your microk8s cluster. 

# Introducing ArgoCD

[ArgoCD](https://argoproj.github.io/cd/) is a GitOps style continuous delivery tool for Kubernetes.
Argo CD follows the GitOps pattern of using Git repositories as the source of truth for defining the state of your application and infrastructure. 
In Kubernetes, you can define the desired state of your application and environments in manifest files.
These files can be pushed to a Git Repository and subsequently tagged.  

ArgoCD automates the deployment of these manifest files to the Kubernetes cluster.
Instead of using a classic push-style CD pipeline to push your desired application state to the cluster, ArgoCD uses a pull-based approach by monitoring changes in your Git repository.
If any changes are detected, ArgoCD will update the application state to the newly desired state.

More information can be found in the official [ArgoCD documentation](https://argo-cd.readthedocs.io/en/stable/)

to get an in-depth introduction of ArgoCD, I can recommend the video below:

{% include video id="MeU5_k9ssrs" provider="youtube" %}


# Installing ArgoCD

Installing ArgoCD is made relatively with the official [getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/) page.
There is one big caveat though: the latest release does not support ARM architecture just yet, but it's scheduled for an [upcoming release](https://blog.argoproj.io/argo-cd-v2-3-release-candidate-a5b8cf11b0d3).  
When using the latest release the argcd-applicationset-controller will not start because it's the only component not yet working on ARM64.

## Modify the installation manifest
In order to fix the installation we need to replace the image for the apllicationset-controller with an image built for arm64.
GitHub user [jr64](https://github.com/argoproj/argo-cd/issues/8394#issuecomment-1046013264) made such an image available until there will be official support.

Copy the [install manifest](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml) to a file:

{% highlight bash %}
wget https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > install.yaml
{% endhighlight %}

and edit the file:

{% highlight bash %}
nano install.yaml
{% endhighlight %}

In the Deployment section of the [install manifest](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml) replace the application-controller image:
{% highlight yaml %}
image: quay.io/argoproj/argocd-applicationset:v0.4.1
{% endhighlight %}

with:
{% highlight yaml %}
image: ghcr.io/jr64/argocd-applicationset:v0.4.0
{% endhighlight %}

So it looks like the following:

{% highlight yaml %}
...
  template:
    metadata:
      labels:
        app.kubernetes.io/name: argocd-applicationset-controller
    spec:
      containers:
      - command:
        - entrypoint.sh
        - applicationset-controller
        env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        image: ghcr.io/jr64/argocd-applicationset:v0.4.0
        imagePullPolicy: Always
        name: argocd-applicationset-controller
...
{% endhighlight %}



## Install the manifest

you can now install ArgoCD by applying the file with kubectl:

{% highlight bash %}
kubectl create namespace argocd
kubectl apply -n argocd -f install.yaml
{% endhighlight %}

# Install the ArgoCD CLI
The ArgoCD CLI binaries can be found in the Asset section of the ArgoCD [release page](https://github.com/argoproj/argo-cd/releases/tag/v2.3.3). 

Installation instruction be found [here](https://argo-cd.readthedocs.io/en/stable/cli_installation/):

{% highlight bash %}
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
chmod +x /usr/local/bin/argocd
{% endhighlight %}


# Exposing the ArgoCD UI with a load balancer

In order to manage ArgoCD with the UI that the default installation comes with we have to attach an external IP to the UI service.

**in progress**

## Enabling the Metallb load balancer

**in progress**




