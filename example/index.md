---
layout: default
title: Home
---

# Document Management Example

This is a demonstration of the **jekyll-documents** plugin.

## Features

- Automatic document page generation
- Category-based organization
- Date-based sorting
- Full-text search with Lunr.js
- File type icons
- Sitemap integration

## Latest Documents

{% include latest_documents.html count=5 %}

## All Documents

{% include documents_list.html %}

## Categories

{% include category_list.html %}

## Search Documents

{% include documents_search.html %}

<script src="https://unpkg.com/lunr/lunr.js"></script>
<script src="{{ '/assets/js/documents-search.js' | relative_url }}"></script>
