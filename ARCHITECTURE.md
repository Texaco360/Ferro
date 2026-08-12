# FerroServer Architecture

This document describes the current API architecture used in FerroServer.

## Overview

FerroServer follows a layered pattern:

1. Controller
2. Service
3. Repository
4. Resource
5. DTO

Each layer has one clear responsibility.

## Layer Responsibilities

### Controller Layer

Location: `src/controllers/*_controller.pas`

Responsibilities:
- Receive HTTP request/response objects (Horse callbacks)
- Parse request payload into DTOs
- Call service methods
- Map service output to JSON through resource classes
- Return HTTP status codes

Controllers should not contain business rules or SQL.

### Service Layer

Location: `src/services/*_service.pas`

Responsibilities:
- Enforce business validation rules
- Coordinate repository calls
- Return typed DTOs to controller
- Shape output independently from the input DTO when needed

Services should not parse raw HTTP JSON and should not render JSON responses.

### Repository Layer

Location: `src/repositories/*_repository.pas`

Responsibilities:
- Run SQL queries and transactions
- Map database rows to typed DTO objects
- Return typed DTOs (or DTO lists)

Repositories should not know about HTTP or response formatting.

### Resource Layer

Location: `src/resources/*_resource.pas`

Responsibilities:
- Convert DTO objects to API JSON shape
- Keep response formatting consistent across endpoints

Resources should be the only place where API response JSON is assembled.

### DTO Layer

Location: `src/dto/*.pas`

Responsibilities:
- Represent transport data passed between layers
- Parse request JSON via factory methods
- Carry typed fields across service/repository boundaries
- Support separate request and response shapes when a use case needs them

## Reusable Base DTO

Shared base class:
- `src/dto/base_dto.pas`

`TBaseDTO` provides reusable request parsing and validation helpers:
- Parse request body as JSON object
- Require string fields
- Require boolean fields

Model DTO classes (for example `TTodoDTO`, `TProjectDTO`) inherit from `TBaseDTO` and expose model-specific factory methods such as:
- `FromCreateJSON`
- `FromUpdateJSON`

In practice, the request DTO passed into a service does not need to be identical to the DTO returned by that service. The service can return a richer, thinner, or otherwise transformed DTO that matches the response contract better than the input contract.

## Ownership Rules

DTOs are class instances, so ownership is explicit:

- Controller owns request DTOs and frees them.
- Service returns response DTOs; controller frees them after rendering.
- Repository list methods return owned object lists (for example `TObjectList` descendants with `OwnsObjects=True`); caller frees the list.

Keeping ownership explicit avoids leaks and double free errors.

## Typical Request Flow

1. Route calls controller method.
2. Controller parses `Req.Body` into DTO.
3. Controller calls service with DTO.
4. Service validates and calls repository.
5. Repository returns DTO(s).
6. Service may return a different DTO shape than the request DTO if the response contract requires it.
7. Controller uses resource mapper to convert DTO(s) to JSON.
8. Controller sends HTTP response.

## Why This Pattern

Benefits:
- Clear separation of concerns
- Reusable validation and parsing logic
- Strongly typed data flow instead of generic JSON everywhere
- Easier unit testing per layer
- Predictable API response formatting

## Adding A New Entity

For a new entity, keep the same pattern:

1. Add DTO class in `src/dto` inheriting from `TBaseDTO`
2. Add repository returning typed DTO(s)
3. Add service with validation/business logic
4. Add resource class for response rendering
5. Add controller methods using DTO factory methods and resource mappers
6. Register routes

This keeps all modules consistent and easier to maintain.
