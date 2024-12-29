# Knowleverage AI

## About

An **open source** framework for **growing knowledge bases** in **cooperation
with AI agents**.

For public or organizational information of any domain.

Use a **markdown repository** and let the agents help you

* **digesting new information** from **any source**, such as blog posts,
  Youtube videos or release tags,
* **extracting new knowledge** from those sources,
* adding that knowledge to the **markdown repository** in a **structured** way,
* thereby **re-organizing existing pages** where needed,
* including **references to the sources** digested.

There is also a **"This week in ..." recap** agent summarizing the latest
changes.

All with (default mode) or even without (demo mode) **human approval**.

Knowleverage AI is an **extendible Ruby on Rails 8 application** and *looking
for open source contributors*.

We are **passionate** about **learning, sharing knowledge and developing**.

This framework **enpowers** us to use **AI for leveraging** the **assimilation
of knowledge**.

## Agents

[Solid Queue](https://github.com/rails/solid_queue) is used for providing a
consistent handling and chaining of agents.

### Getting started: extract from collection article

A *collection article* is a web page containing a list of URLs to *single
articles*, usually with some short-descriptive context.

As an initial feature, the information contained in both the descriptions and
the articles themselves shall be extracted and put into a markdown overview
page and sub-pages for details, with sub-pages being defined by topics, not 1:1
per single article.

*Tasks to be implemented.*

#### Prepare git branch

*Assumption: markdown repository is empty and is accessible on Github.*

1. Clone markdown repository into a data folder if not existing yet.
1. Check out fresh branch.

#### Extract single article references

1. Read collection article.
1. Extract URLs to single articles and their short descriptions.

#### Extract knowledge from single articles

1. Read single article.
1. Summarize key points, grouped by (sub-) topics.
1. Store information along with their (sub-) topics.
1. Flush markdown files everytime an article got covered.

NOTE: probably helpful to modelize topics and information in database.

### Push changes, create merge request

1. Push git changes for markdown repository.
1. On first push, create merge request.

## Development

### Next steps

Evaluate [langchainrb](https://rubydoc.info/gems/langchainrb).

Explore vector databases and markdown repository projection.

Use RSS reader. Integrate Instapaper API.

Use a Ruby git client and a Gitlab/Github client.

Way more stuff:

* [Awesome Machine Learning with Ruby](https://github.com/arbox/machine-learning-with-ruby)
* [AI Engineering Book: Resources](https://github.com/chiphuyen/aie-book/blob/main/resources.md)
