import { HttpsProxyAgent } from 'https-proxy-agent';

export const getProxyAgent = (url: string): HttpsProxyAgent<string> | undefined => {
    if (url.includes('localhost')) {
      return undefined;
    }

    const proxy = process.env['http_proxy']
      || process.env['https_proxy']
      || process.env['HTTP_PROXY']
      || process.env['HTTPS_PROXY'];

    if (proxy) {
        return new HttpsProxyAgent(proxy);
    }

    return undefined;
};
