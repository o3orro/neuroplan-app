FROM nginx:alpine

RUN echo '<h1>NeuroPlan CI/CD Success V2</h1>' \
    > /usr/share/nginx/html/index.html

EXPOSE 80
