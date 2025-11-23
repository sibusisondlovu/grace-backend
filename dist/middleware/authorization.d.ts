import { Request, Response, NextFunction } from 'express';
type AppRole = 'admin' | 'speaker' | 'chair' | 'deputy_chair' | 'whip' | 'member' | 'external_member' | 'coordinator' | 'clerk' | 'legal' | 'cfo' | 'public' | 'super_admin';
interface UserContext {
    id: string;
    email: string;
    organizationId?: string;
    roles: AppRole[];
    committeeIds: string[];
}
declare global {
    namespace Express {
        interface Request {
            userContext?: UserContext;
        }
    }
}
export declare const loadUserContext: (req: Request, res: Response, next: NextFunction) => Promise<Response<any, Record<string, any>> | undefined>;
export declare const hasRole: (...requiredRoles: AppRole[]) => (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>> | undefined;
export declare const isAdmin: (req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>> | undefined;
export declare const hasOrganizationAccess: (req: Request, res: Response, next: NextFunction) => void | Response<any, Record<string, any>>;
export declare const hasCommitteeAccess: (committeeId: string, userId: string, userContext: UserContext) => Promise<boolean>;
export declare const checkCommitteeAccess: (req: Request, res: Response, next: NextFunction) => Promise<void | Response<any, Record<string, any>>>;
export declare const getOrganizationFilter: (userContext: UserContext) => string | null;
export declare const getCommitteeFilter: (userContext: UserContext) => string[] | null;
export {};
//# sourceMappingURL=authorization.d.ts.map