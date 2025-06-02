# scripts/cron_wrapper.py
import subprocess
import logging
import config
logging.basicConfig(filename=config.LOG_DIR+"/cron.log", level=logging.INFO)
def run():
    res = subprocess.run(["python3", "scripts/ghost_recon_ultimate.py"], capture_output=True)
    logging.info(res.stdout.decode())
    logging.error(res.stderr.decode())
if __name__ == "__main__":
    run()
