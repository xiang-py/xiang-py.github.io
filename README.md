# Pingyu Xiang's Personal Website

Source code for [xiang-py.github.io](https://xiang-py.github.io), built with [Jekyll](https://jekyllrb.com/) and the [al-folio](https://github.com/alshedivat/al-folio) academic theme.

## Updating Content

The main content is maintained in the following files:

- Homepage: `_pages/about.md`
- Publications: `_bibliography/papers.bib`
- News: `_news/`
- Photography albums: `_data/photography.yml`
- Photography images: `assets/img/photography/`
- Links: `_data/related_links.yml`
- Link images: `assets/img/related/`
- Social profiles: `_data/socials.yml`

Publication preview images belong in `assets/img/publication_preview/`, and publication PDFs belong in `assets/pdf/Publications/`. After adding or replacing a preview image, run `powershell -ExecutionPolicy Bypass -File scripts/generate-publication-thumbnails.ps1`; detailed instructions are in `assets/img/publication_preview/README.md`.

## Local Preview

Docker Desktop is the only required local dependency.

Start the website from the repository root:

```powershell
docker compose up -d
```

Open [http://127.0.0.1:8080](http://127.0.0.1:8080). Changes are rebuilt automatically while the container is running.

View recent logs:

```powershell
docker compose logs --tail=80
```

Stop the website:

```powershell
docker compose down
```

## Publishing

Pushing the source files to `main` triggers the `Deploy site` GitHub Actions workflow. The generated website is written to `gh-pages`; do not edit that branch manually.

```powershell
git switch main
git pull --ff-only origin main
git add -A
git commit -m "Update website"
git push origin main
```

Deployment progress is available in the repository's [Actions page](https://github.com/xiang-py/xiang-py.github.io/actions).

## Documentation

Detailed theme customization and maintenance documentation remains available in [`docs/`](docs/). Repository-specific agent guidance is in [`AGENTS.md`](AGENTS.md).

## License and Credits

This website is based on al-folio and distributed under the terms of the repository's [MIT License](LICENSE).
