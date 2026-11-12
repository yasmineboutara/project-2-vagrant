FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server python3 sudo ca-certificates && rm -rf /var/lib/apt/lists/* && \
    useradd --create-home --shell /bin/bash deploy && \
    install -d -m 700 -o deploy -g deploy /home/deploy/.ssh && install -d -m 755 -o root -g root /run/sshd && \
    echo 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deploy && chmod 440 /etc/sudoers.d/deploy && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
ARG SSH_PUBLIC_KEY
RUN test -n "$SSH_PUBLIC_KEY" && echo "$SSH_PUBLIC_KEY" > /home/deploy/.ssh/authorized_keys && chown deploy:deploy /home/deploy/.ssh/authorized_keys && chmod 600 /home/deploy/.ssh/authorized_keys
EXPOSE 22 80
CMD ["/bin/sh", "-c", "ssh-keygen -A && exec /usr/sbin/sshd -D -e"]
