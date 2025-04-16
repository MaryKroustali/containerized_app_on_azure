# Containerized App on Azure

This repository focuses on the containerization of the [Record Store Application](https://github.com/MaryKroustali/record_store_app) and its deployment on Azure Container Instances.

## Preparation
The application gets upgraded to ASP.NET Core so it can easily get containerized in a Linux container using this [Visual Studio 2022](https://learn.microsoft.com/en-us/aspnet/core/migration/mvc?view=aspnetcore-9.0)

## Containerization
The application gets containerized using [Visual Studio Container Tools](https://learn.microsoft.com/en-us/visualstudio/containers/overview?view=vs-2022&toc=%2Fdotnet%2Fnavigate%2Fdevops-testing%2Ftoc.json&bc=%2Fdotnet%2Fbreadcrumb%2Ftoc.json) or [Docker Desktop](https://learn.microsoft.com/en-us/dotnet/core/docker/build-container?tabs=linux&pivots=dotnet-8-0#create-the-dockerfile).

### Dockerfile
```Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0@sha256:35792ea4ad1db051981f62b313f1be3b46b1f45cadbaa3c288cd0d3056eefb83 AS build
WORKDIR /App

# Copy everything
COPY . ./
# Restore as distinct layers
RUN dotnet restore
# Build and publish a release
RUN dotnet publish -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0@sha256:6c4df091e4e531bb93bdbfe7e7f0998e7ced344f54426b7e874116a3dc3233ff
WORKDIR /App
COPY --from=build /App/out .
# Replace with project's dll file
ENTRYPOINT ["dotnet", "WebApplication8Core.dll"]
```

A container image `record-store-app` is built using Dockerfile and executing below command inside the Dockerfile's directory.
```bash
docker build -t record-store-app .
```

### Local Execution
To test the application, create a container locally to test the application
```bash
sudo docker run -p 8080:8080 -it --rm record-store-app
```

Visit http://localhost:8080

![Containerized App](images/app-container.png)

### Container Registry
To make the image available upload it to a registry like [Github Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

1. authenticating to the registry where \<USERNAME>  is the user profile name
```bash
export CR_PAT=<PAT> # ensure pat has write packages permission
echo $CR_PAT | docker login ghcr.io -u <USERNAME> --password-stdin
```
tagging and uploading the image
```bash
docker tag record-store-app ghcr.io/<USERNAME>/record-store-app:1.0.0
docker push ghcr.io/<USERNAME>/record-store-app:1.0.0
```
The image is now available at Pachages Section and can be pulled using
```
docker pull ghcr.io/USERNAME/record-store-app:1.0.0
```

## Hosting on Azure
To host the app on Azure, the arcitecture used in [private_app_on_azure](https://github.com/MaryKroustali/private_app_on_azure) repository can be used. An App Service can also work with containers by using `linuxFxVersion` property.
```bicep
resource app_service 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  properties: {
    serverFarmId: asp_id
    siteConfig: {
      linuxFxVersion: 'ghcr.io/<USERNAME>/record-store-app:1.0.0'
    }
  }
}
```

Alternatively, Azure provides [container-based](https://azure.microsoft.com/en-us/products/category/containers) solutions. The following architecture will be used:

[diagram]
- acr to host the container image on azure
- vnet
- container instance to host the app
- sql?