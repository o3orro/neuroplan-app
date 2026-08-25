FROM nginx:alpine

RUN echo '<h1>NeuroPlan CI/CD Success V3 - Ansible Managed</h1>' \
    > /usr/share/nginx/html/index.html

EXPOSE 80
