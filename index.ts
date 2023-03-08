import { createConnectTransport } from "@bufbuild/connect-node"
import { Interceptor, createPromiseClient } from "@bufbuild/connect";
import { experimental } from "@gitpod/public-api"

const PAT = "YOUR PAT";
const WORKSPACE_ID = process.env.GITPOD_WORKSPACE_ID ?? "YOUR WS ID"

async function start() {
    const authInterceptor: Interceptor = (next) => async (req) => {
        req.header.set('Authorization', `Bearer ${PAT}`);
        return await next(req);
    };

    console.log(new Date())
    const transport = createConnectTransport({
        baseUrl: 'https://api.gitpod.io',
        httpVersion: '2',
        interceptors: [authInterceptor],
        useBinaryFormat: true,
    });
    const workspaceService = createPromiseClient(experimental.WorkspacesService, transport);

    let previous = experimental.PortPolicy.PRIVATE

    setTimeout(() => {
        const policy = previous === experimental.PortPolicy.PRIVATE ? experimental.PortPolicy.PUBLIC : experimental.PortPolicy.PRIVATE
        console.log(new Date(), 'going to change port policy')
        workspaceService.updatePort({ port: { port: BigInt(3000), policy } }).catch(console.error)
    }, 15 * 60 * 1000)

    try {

        const wsStatus = workspaceService.streamWorkspaceStatus({ workspaceId: WORKSPACE_ID })
        for await (const status of wsStatus) {
            if ((status.result?.instance?.status?.ports?.length ?? 0) > 0) {
                const port = status.result?.instance?.status?.ports[0]
                console.log(new Date(), `port:${port?.port} - ${port?.policy.toString()}`)
            } else {
                console.log(new Date(), status.result?.instance?.status?.phase, 'phase')
            }
        }
    } catch (e) {
        console.log(new Date(), e, '=========')
        console.error(e)
    }
}

start().then(console.log).catch(console.error)