# Build stage: restore from lock files first so the layer is cached until packages change.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY Directory.Build.props Directory.Packages.props ./
COPY src/Velomine.Server/Velomine.Server.csproj src/Velomine.Server/packages.lock.json src/Velomine.Server/
RUN dotnet restore src/Velomine.Server/Velomine.Server.csproj --locked-mode
COPY src/Velomine.Server src/Velomine.Server
RUN dotnet publish src/Velomine.Server/Velomine.Server.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app .
# The aspnet image ships a non-root "app" user; files live on a volume it can write to.
RUN mkdir -p /data/files && chown app /data/files
USER app
ENV ASPNETCORE_HTTP_PORTS=8080 \
    Velomine__FilesPath=/data/files
EXPOSE 8080
ENTRYPOINT ["dotnet", "Velomine.Server.dll"]
