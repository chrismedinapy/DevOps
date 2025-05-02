FROM node:22-slim
WORKDIR /app
COPY app /app
RUN apt-get update && apt-get upgrade -y
RUN npm install
RUN npm run build
RUN npm run test
EXPOSE  3000
CMD ["npm", "run", "start"]
