import markdown

with open("README_DEPLOY_COMPLETO.md", "r", encoding="utf-8") as f:
    text = f.read()
    html = markdown.markdown(text)

with open("README_DEPLOY_COMPLETO.html", "w", encoding="utf-8") as f:
    f.write(html)
