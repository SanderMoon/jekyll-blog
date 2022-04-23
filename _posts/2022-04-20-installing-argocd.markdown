---
layout: single
title:  "Installing ArgoCD on Raspberry Pi 4 with microk8s"
date:   2022-01-13 13:30:05 +0100
categories: Technical
toc: true
---

Currently this website is running on my Raspberry Pi cluster at home.
The cluster consists of three Raspberry Pi 4 boards, running in a high availability (HA) configuration in Kubernetes.
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

to get an in-depth tutorial about ArgoCD, I can recommend this video below:

{% include video id="MeU5_k9ssrs" provider="youtube" %}


# Installing ArgoCD

Installing ArgoCD is made relatively easy with the official [getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/) page.
There is one big caveat though: the latest release does not support ARM architecture just yet, but it's scheduled for an [upcoming release](https://blog.argoproj.io/argo-cd-v2-3-release-candidate-a5b8cf11b0d3).  

When using the latest release, the argcd-applicationset-controller will not start because it's the only component not yet working on ARM64.
This means that you won't be able to use ArgoCD on your RPi cluster out-of-the-box.

## Modify the installation manifest
In order to fix the installation we need to replace the image for the apllicationset-controller with an image built for the ARM64 architecture.
GitHub user [jr64](https://github.com/argoproj/argo-cd/issues/8394#issuecomment-1046013264) made such an image available which can be used until ARM64 will be officially supported.

Copy the ArgoCD [install manifest](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml) to a file:

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

<pre>

</pre>

# Exposing the ArgoCD UI with a load balancer

ArgoCD comes with a UI to help you easily manage your applications. As ArgoCD is running in your K8s cluster and we want to access this UI outside of our cluster, we need to expose the service for the UI to the outisde world. We can do this in a number of ways, also described in the ArgoCD [getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/) page. As i only want to use ArgoCD in my local network from another machine, I've decided to expose the service with a Kubernetes Loadbalancer. 

Microk8s does not come out of the box with a loadbalancer implementation, but it does contain an [addon](https://microk8s.io/docs/addon-metallb) we can install, namely metallb. [MetalLB](https://microk8s.io/docs/addon-metallb) is a loadbalancer implementation for bare-metal clusters. We need this type of load balancer because Kubernetes only comes with load balancers for IaaS platforms like Azure, AWS or GCP. 

## Enabling the Metallb load balancer

Microk8s makes it fairly easy to enable metallb by enabling it through the CLI:

{% highlight bash %}
microk8s enable metallb
{% endhighlight %}

You will be asked to provide an IP range that can be used by metallb: 
{% highlight bash %}

Enabling MetalLB
Enter each IP address range delimited by comma (e.g. 
‘10.64.140.43–10.64.140.49,192.168.0.105–192.168.0.111’): 
192.168.178.XXX-192.168.178.XXX

{% endhighlight %}

**Make sure that you give an IP range that does not conflict with any IP addresses reserved by your DHCP server.**

## Set service type to loadbalancer

You can now follow the regular aproach outlined in Step 3 of the ArgoCD [getting started](https://argo-cd.readthedocs.io/en/stable/getting_started/) page by patching the service of the argocd-server:

{% highlight bash %}
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
{% endhighlight %}

After waiting a few moments and fetching the service in the argocd namespace you can see that an External IP was assigned to the argocd-server service:

{% highlight bash %}
$ kubectl get svc -n argocd
NAME                                      TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)                      AGE
...                                       ...            ...              ...               ...
argocd-server                             LoadBalancer   XX.XXX.XXX.XXX   192.168.178.XXX   80:31083/TCP,443:30471/TCP   5d23h  
{% endhighlight %}

After this follow step 4 of the getting started page to change your admin password.

## Access ArgoCD UI
You can now access the ArgoCD UI by browsing to the external IP that was assigned to the service!

![alt]({{ site.url }}{{ site.baseurl }}/assets/images/ArgoCD-UI.png)

# Conclusion
You are now able to use argoCD on your Raspberry Pi cluster!

I hope you enjoyed the read, and stay tuned for more related posts about kubernetes on a RPi cluster.


