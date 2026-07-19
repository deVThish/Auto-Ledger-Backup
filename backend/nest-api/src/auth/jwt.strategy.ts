import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';

interface JwtPayload {
  sub: string;
  role: string;
  badgeNo?: string;
  divisionId?: string;
  headId?: string;
  nic?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      throw new Error('JWT_SECRET environment variable is not set');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: jwtSecret,
    });
  }

  validate(payload: JwtPayload) {
    if (payload.role === 'USER') {
      return { id: payload.sub, role: payload.role, nic: payload.nic };
    }

    if (payload.role === 'DMT_ADMIN' || payload.role === 'POLICE_ADMIN') {
      return { id: payload.sub, role: payload.role };
    }

    return {
      id: payload.sub,
      role: payload.role,
      badgeNo: payload.badgeNo,
      divisionId: payload.divisionId,
      headId: payload.headId,
    };
  }
}
