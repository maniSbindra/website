DOCKER       = docker
HUGO_VERSION = 0.52
DOCKER_IMAGE = kubernetes-hugo
DOCKER_RUN   = $(DOCKER) run --rm --interactive --tty --volume $(CURDIR):/src
NODE_BIN     = node_modules/.bin
A11Y         = $(NODE_BIN)/a11ym
NETLIFY_FUNC = $(NODE_BIN)/netlify-lambda

.PHONY: all build sass build-preview help serve

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: build ## Build site with production settings and put deliverables in ./public

build: ## Build site with production settings and put deliverables in ./public
	hugo --minify

build-preview: ## Build site with drafts and future posts enabled
	hugo --buildDrafts --buildFuture

functions-build:
	$(NETLIFY_FUNC) build functions-src

check-headers-file:
	scripts/check-headers-file.sh

production-build: build check-headers-file accessibility-page ## Build the production site and ensure that noindex headers aren't added

non-production-build: ## Build the non-production site, which adds noindex headers to prevent indexing
	hugo \
		--enableGitInfo \
		--baseURL $(DEPLOY_PRIME_URL)
	make accessibility-page

sass-build:
	scripts/sass.sh build

sass-develop:
	scripts/sass.sh develop

serve: ## Boot the development server.
	hugo server --ignoreCache --buildFuture

docker-image:
	$(DOCKER) build . --tag $(DOCKER_IMAGE) --build-arg HUGO_VERSION=$(HUGO_VERSION)

docker-build:
	$(DOCKER_RUN) $(DOCKER_IMAGE) hugo

docker-serve:
	$(DOCKER_RUN) -p 1313:1313 $(DOCKER_IMAGE) hugo server --buildFuture --bind 0.0.0.0

# This command is used only by Travis CI; do not run this locally
travis-hugo-build:
	curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-64bit.tar.gz | tar -xz
	mkdir -p ${TRAVIS_HOME}/bin
	mv hugo ${TRAVIS_HOME}/bin
	export PATH=${TRAVIS_HOME}/bin:$PATH

check-hugo-versions:
	scripts/hugo-version-check.sh $(HUGO_VERSION)

accessibility-page:
	$(A11Y) \
	--output-directory public/accessibility \
	--maximum-urls 10 \
	https://kubernetes.io
