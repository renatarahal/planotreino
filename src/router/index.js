import { createRouter, createWebHistory } from 'vue-router'
import { estaLogado, perfilAtual } from '../session'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/perfis' },
    { path: '/login', component: () => import('../views/LoginView.vue'), meta: { publica: true } },
    { path: '/perfis', component: () => import('../views/PerfisView.vue') },
    {
      path: '/treinos',
      component: () => import('../views/TreinosView.vue'),
      meta: { precisaPerfil: true },
    },
  ],
})

router.beforeEach(async (to) => {
  const logado = await estaLogado()
  if (!to.meta.publica && !logado) return '/login'
  if (to.path === '/login' && logado) return '/perfis'
  if (to.meta.precisaPerfil && !perfilAtual.value) return '/perfis'
})

export default router
