FROM nginx:alpine

RUN echo '<h1>NeuroPlan CI/CD Success</h1>' \
    > /usr/share/nginx/html/index.html

EXPOSE 80
