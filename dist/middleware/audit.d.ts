import { Request } from 'express';
export declare const auditLog: (userId: string, action: string, tableName: string, recordId: string | null, changes?: Record<string, any>) => Promise<void>;
export declare const auditMiddleware: (action: string) => (req: Request, res: any, next: any) => Promise<void>;
//# sourceMappingURL=audit.d.ts.map