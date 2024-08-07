**These Optimization Tools perform various operations with the goal of improving performance of this application. Typically this will effect startup and load time performance, and potentially other areas**

#####__IMPORTANT__

%{color:RED} ❗% %{color:RED}**FOR ADVANCED USERS ONLY!**% 

%{color:#FFFFD265} ❗% Do not use if you do not know what you are doing!

%{color:#FFFFD265} ❗% These tools and optimizations are not guaranteed to improve performance on all machines. It is highly recommended to only use these tools if you understand what they do and how they effect your PC's enviroment!

%{color:#FFFFD265} ❗% Please read through each tools description to understand their purpose and how they may effect your system. This is Windows we are talking about, so there is always a chance it can make things worse!

######__OPTIMIZE ASSEMBLIES__

The Optimize Assemblies tool performs 2 primary operations. 

  1. %{color:green}✔% Installs all dll assemblies include with this app into the GAC (Global Assembly Cache)

  2. %{color:green}✔% Executes "NGEN install" on all CurrentDomain Assemblies

__**1. Install to GAC**__

%{color:cyan} ❓% The goal is to improve load times of commonly used assemblies. By installing this apps assemblies into the GAC, it can improve performance of many areas of the app including startup, media load times and general usage.

%{color:cyan} ❓% For more information about what GAC, highly recommend reviewing this link: [Global Assembly Cache](https://learn.microsoft.com/en-us/dotnet/framework/app-domains/gac?redirectedfrom=MSDN)

__**2. NGEN**__

%{color:cyan} ❓% The goal with NGEN is to improve general startup performance of the app by generating Native Images for .NET assemblies and libraries. This optimization affects more than just this specific app, as these changes effect the underlying Powershell engine, potentially improving startup of all Powershell sessions, scripts and apps

%{color:cyan} ❓% For more information about what ngen does, highly recommend reviewing this link: [Improving startup performance with NGen](https://learn.microsoft.com/en-us/ef/ef6/fundamentals/performance/ngen)

######__INFO__

%{color:cyan} ❓% These Optimization Tools should not need to be run very often. As a general rule, its recommended to only run them when there has been an update or install of .NET runtimes or an install of a major Windows version/update. 

%{color:cyan} ❓% It may also be beneficial to run these tools when installing or upgrading to a new version of this application. Primarily after the first time installing, after that there is likely diminishing returns. It can vary greatly from system to system.

%{color:cyan} ❓% Don't take this as gospel as this only barely touches on these topics, which is why its highly recommended to review the links provided above to learn more. 