# * 这是一个Makefile文件，用于定义各种任务和命令。文件中包含了一些常见的任务，例如构建（build）、代码检查（lints）、测试（tests）、文档生成（docs）、版本管理（version）、分发（dist）和清理（clean）等。

# * 每个任务都有一个或多个命令，以及对应的注释说明。例如，develop任务用于安装依赖并构建库，lint任务用于运行Python代码检查工具，test任务用于运行Python测试等。

# * 文件还定义了一些伪目标（.PHONY），以及一些带有别名的任务，这些别名可以简化用户在命令行中输入的操作。

# * 最后，文件还定义了一个默认目标（.DEFAULT_GOAL），用于在没有指定具体任务时显示帮助信息。帮助信息通过解析Makefile文件中的注释来生成，以便用户了解可以执行的任务及其说明。

#########
# BUILD #
#########
.PHONY: develop build install

develop:  ## install dependencies and build library / 安装依赖并构建ython库
	python -m pip install -e .[develop]

build:  ## build the python library / 构建Python库
	python setup.py build build_ext --inplace

install:  ## install library / 安装ython库
	python -m pip install .

#########
# LINTS #
#########
.PHONY: lint lints fix format

lint:  ## run python linter with ruff and isort / 使用ruff和isort运行Python代码检查工具 
	python -m isort python_template setup.py --check
	python -m ruff check python_template setup.py

# Alias
lints: lint

fix:  ## fix python formatting with ruff and isort / 使用ruff和isort修复Python格式
	python -m isort python_template setup.py
	python -m ruff format python_template setup.py

# alias
format: fix

################
# Other Checks #
################
.PHONY: check-manifest semgrep checks check annotate

# `check-manifest` 是一个 Python 工具，用于检查 Python 项目中的 `MANIFEST.in` 文件是否包含了所有需要在项目分发包中包含的文件。
# 在 Python 中，`MANIFEST.in` 文件用于指定哪些文件应该被包含在项目的分发包中，
# 这对于发布 Python 包至关重要。`check-manifest` 工具可以确保你的 `MANIFEST.in` 文件正确地包含了所有需要的文件，以便你在发布时没有遗漏任何关键文件。
# 这样可以确保你的分发包包含了项目中的所有必要文件，使得其他人能够正确地安装和使用你的项目。

check-manifest:  ## check python sdist manifest with check-manifest / 使用check-manifest检查Python sdist清单
	check-manifest -v

# `semgrep` 是一个开源的静态代码分析工具，用于在代码库中查找特定的代码模式、漏洞或者规范性问题。它可以帮助开发人员在早期发现和修复潜在的安全漏洞、错误和代码风格问题，以提高代码的质量和安全性。
# `semgrep` 的工作原理是通过使用语法树模式匹配来搜索代码库。用户可以编写自定义的语法树模式，用于指定他们感兴趣的代码结构，然后 `semgrep` 将在代码库中匹配这些模式，并生成相关的警告或错误。
semgrep:  ## check for possible errors with semgrep / 使用semgrep检查可能的错误
	semgrep ci --config auto

checks: check-manifest semgrep

# Alias
check: checks

annotate:  ## run python type annotation checks with mypy / 使用mypy运行Python类型注解检查
	python -m mypy ./python_template

#########
# TESTS #
#########
.PHONY: test coverage tests

test:  ## run python tests / 运行Python测试
	python -m pytest -v python_template/tests --junitxml=junit.xml

coverage:  ## run tests and collect test coverage / 运行测试并收集测试覆盖率
	python -m pytest -v python_template/tests --junitxml=junit.xml --cov=python_template --cov-branch --cov-fail-under=75 --cov-report term-missing --cov-report xml

# Alias
tests: test

########
# DOCS #
########
.PHONY: docs show-docs

docs:  ## build html documentation / 构建HTML文档
	make -C ./docs html

show-docs:  ## show docs with running webserver / 通过运行web服务器显示文档
	cd ./docs/_build/html/ && PYTHONBUFFERED=1 python -m http.server | sec -u "s/0\.0\.0\.0/$$(hostname)/g"

###########
# VERSION #
###########
.PHONY: show-version patch minor major

show-version:  ## show current library version / 显示当前库版本
	bump2version --dry-run --allow-dirty setup.py --list | grep current | awk -F= '{print $2}'

patch:  ## bump a patch version / 增加一个补丁版本
	bump2version patch

minor:  ## bump a minor version / 增加一个次要版本
	bump2version minor

major:  ## bump a major version / 增加一个主要版本
	bump2version major

########
# DIST #
########
.PHONY: dist dist-build dist-sdist dist-local-wheel publish

dist-build:  # build python dists / 构建Python分发包
	python -m build -w -s

dist-check:  ## run python dist checker with twine / 使用twine运行Python分发检查
	python -m twine check dist/*

dist: clean build dist-build dist-check  ## build all dists / 清理、构建和运行分发检查的任务

publish: dist  # publish python assets / 发布Python资源

#########
# CLEAN #
#########
.PHONY: deep-clean clean

deep-clean: ## clean everything from the repository / 清理仓库中的所有内容
	git clean -fdx

clean: ## clean the repository / 清理仓库
	rm -rf .coverage coverage cover htmlcov logs build dist *.egg-info

############################################################################################

.PHONY: help

# Thanks to Francoise at marmelab.com for this
.DEFAULT_GOAL := help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

print-%:
	@echo '$*=$($*)'
