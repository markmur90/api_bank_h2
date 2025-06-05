# scripts/ghost_recon_ultimate.py
import asyncio
import logging
import config
from reconocimiento.models import IntentoReconocimiento, UrlMonitoreada
from playwright.async_api import async_playwright
logging.basicConfig(filename=config.LOG_DIR+"/ghost_recon.log", level=logging.INFO)
async def main():
    urls = UrlMonitoreada.objects.values_list("url", flat=True)
    for url in urls:
        intento = IntentoReconocimiento(url=url)
        intento.save()
        async with async_playwright() as p:
            browser = await p.firefox.launch()
            page = await browser.new_page()
            try:
                await page.goto(url)
                await asyncio.sleep(config.delay)
                path = f"{config.REPORT_DIR}/{intento.id}.png"
                await page.screenshot(path=path)
                intento.captura = path
                intento.exito = True
            except Exception as e:
                logging.error(str(e))
                intento.exito = False
            finally:
                await page.close()
                await browser.close()
                intento.save()
if __name__ == "__main__":
    asyncio.run(main())
