default: all

blog:
	docker build -f Dockerfile.blog -t newssniffer/blog:latest .

rails:
	docker build -f Dockerfile -t newssniffer:latest .

all: blog rails
