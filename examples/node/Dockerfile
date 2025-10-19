FROM node:22-alpine AS base

# zsh
RUN apk add zsh git curl

# oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# zsh theme
COPY sandbox.zsh-theme /root/.oh-my-zsh/custom/themes/
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="sandbox"/' /root/.zshrc

WORKDIR /workspace
CMD ["zsh"]