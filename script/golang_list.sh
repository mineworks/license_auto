#!/usr/bin/env bash
#go list -f '{{.ImportComment}}{{.Name}}' ./...

# go list -f {{.Deps}} ./...

# This will list out the built-in packages of Golang
# go list std

# 必须在本地安装,我们将下载之
# go list -f {{.Standard}} your_package_name

# 需要把packages安装到本地, 否则异常,
# go list -f {{.Deps}} ./... | tr "[" " " | tr "]" " " | xargs go list -f \
# '{{if not .Standard}}{{.ImportPath}}{{end}}'

# go list -f '{{.ImportPath}}' ./... | xargs -n 1 deplist | grep -v P | sort -u

go list -json ./...