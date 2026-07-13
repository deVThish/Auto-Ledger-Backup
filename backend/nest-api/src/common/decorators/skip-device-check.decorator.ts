import { SetMetadata } from '@nestjs/common';
export const SkipDeviceCheck = () => SetMetadata('skipDeviceCheck', true);
