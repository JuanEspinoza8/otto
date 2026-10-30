import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../logica/categorias_provider.dart';
import 'pantalla_formulario_categoria.dart';
import 'seccion_presupuestos.dart';

class PantallaCategorias extends ConsumerWidget {
  const PantallaCategorias({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoCategorias = ref.watch(categoriasControladorProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Mis Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            floating: true,
            pinned: true,
          ),
          const SliverToBoxAdapter(child: SeccionPresupuestos()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: estadoCategorias.when(
              data: (categorias) {
                if (categorias.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('Aún no tienes categorías.', 
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final categoria = categorias[index];
                      final colorBase = Color(int.parse(categoria.colorHex));
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorBase.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PantallaFormularioCategoria(categoriaAEditar: categoria),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorBase.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(MapeadorIconos.obtenerIcono(categoria.icono), color: colorBase),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoria.nombre,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          categoria.tipo.toUpperCase(),
                                          style: TextStyle(
                                            color: categoria.tipo == 'ingreso' ? Colors.green : Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (categoria.esSistema)
                                    const Icon(Icons.lock_outline, color: Colors.grey, size: 20)
                                  else
                                    const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: categorias.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantallaFormularioCategoria()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }
}
