# Custom Roles

The Custom Roles feature allows you to create and manage specialized machine configurations for your AutomatedLab environments.

## Overview

Custom Roles enable you to:

- Define specialized machine configurations beyond standard templates
- Create reusable role definitions for consistent deployments
- Customize software installations and configurations
- Manage role-specific settings and parameters

## Using Custom Roles

### Creating a New Role

1. Navigate to the "Custom Roles" page
2. Click "Add New Role"
3. Configure role properties:
   - Role name
   - Initialization Script. This can be a `.ps1` file on disk or a link to a `.ps1` file hosted on the, such as in a GitHub Gist.
   - Additional Files (_Optional_) *
4. Click `Create Role`

_* The additional files functionality does not currently work properly in version 1.0.0 but will be added in a future release_
