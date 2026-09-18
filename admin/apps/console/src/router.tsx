import { createRouter as createTanStackRouter } from "@tanstack/react-router";

import { LoadingState } from "./components/console-components";
import { routeTree } from "./routeTree.gen";

export const getRouter = () => {
  const router = createTanStackRouter({
    routeTree,
    scrollRestoration: true,
    defaultPreloadStaleTime: 0,
    context: {},
    defaultPendingComponent: () => <LoadingState />,
    defaultNotFoundComponent: () => (
      <div className="state-panel">
        <h2>Page introuvable</h2>
        <p>Cette adresse ne correspond à aucun espace de la console.</p>
      </div>
    ),
  });

  return router;
};

declare module "@tanstack/react-router" {
  interface Register {
    router: ReturnType<typeof getRouter>;
  }
}
