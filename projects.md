---
layout: page
title: Projects
permalink: /projects/
---

These are my main projects. I do smaller ones all the time, and most of them never even reach the internet. These are the ones I feel are worth mentioning.

<div class="project_card_container">
{% for project in site.data.projects.entries %}

<div class="project_card">
<!--    
    <div class="image_wrapper">
        <img src="https://unsplash.it/500">
    </div>
-->

    <div class="text_container">
        {% if project.link %}
        <a href="{{ project.link }}"><h3>{{ project.title }}</h3></a>
        {% else %}
        <h3>{{ project.title }}</h3>
        {% endif %}

        <div class="status_text">{{ project.status }}</div>

        <div class="bread_text">
            {{ project.description | markdownify }}
        </div>

        <div class="tech_labels">
            {% for label in project.labels %}
                {% assign label_data = site.data.projects.tech_labels[label] %}
                {% assign title = label_data[0] %}
                {% assign background_color = label_data[1] %}
                {% assign text_color = label_data[2] %}
                {% assign link = label_data[3] %}

                <div style="background-color: {{ background_color }}; color: {{ text_color }};">
                {% if link != "" %}
                <a href="{{ link }}">{{ title }}</a>
                {% else %}
                {{ title }}
                {% endif %}
                </div>
            {% endfor %}
        </div>
    </div>
</div>

{% endfor %}
</div>
