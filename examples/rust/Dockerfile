FROM rust:1.89-alpine AS base

# zsh
RUN apk add zsh git curl

# oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# zsh theme
COPY sandbox.zsh-theme /root/.oh-my-zsh/custom/themes/
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="sandbox"/' /root/.zshrc

# rust development essentials
RUN apk add --no-cache build-base musl-dev openssl-dev

# common rust tools
RUN cargo install --locked bacon

# workspace
WORKDIR /workspace
CMD ["zsh"]