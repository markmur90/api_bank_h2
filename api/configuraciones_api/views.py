from django.shortcuts import render, get_object_or_404, redirect
from api.configuraciones_api.models import ConfiguracionAPI
from api.configuraciones_api.forms import ConfiguracionAPIForm

def lista_configuraciones(request):
    configuraciones = ConfiguracionAPI.objects.all()
    return render(request, 'api/configuraciones/lista.html', {'configuraciones': configuraciones})

def crear_configuracion(request):
    form = ConfiguracionAPIForm(request.POST or None)
    if form.is_valid():
        form.save()
        return redirect('lista_configuraciones')
    return render(request, 'api/configuraciones/formulario.html', {'form': form, 'modo': 'crear'})

def editar_configuracion(request, pk):
    configuracion = get_object_or_404(ConfiguracionAPI, pk=pk)
    form = ConfiguracionAPIForm(request.POST or None, instance=configuracion)
    if form.is_valid():
        form.save()
        return redirect('lista_configuraciones')
    return render(request, 'api/configuraciones/formulario.html', {'form': form, 'modo': 'editar'})

def eliminar_configuracion(request, pk):
    configuracion = get_object_or_404(ConfiguracionAPI, pk=pk)
    if request.method == 'POST':
        configuracion.delete()
        return redirect('lista_configuraciones')
    return render(request, 'api/configuraciones/eliminar.html', {'configuracion': configuracion})