# """Compatibilidad de rutas para la app banco."""
# import sys

# default_app_config = 'banco.apps.BancoConfig'
# sys.modules.setdefault('banco', sys.modules[__name__])
# sys.modules.setdefault('simulador_banco.banco', sys.modules[__name__])

# import importlib
# models = importlib.import_module('banco.models')
# sys.modules.setdefault('simulador_banco.banco.models', models)