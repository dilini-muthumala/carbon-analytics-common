<%@ taglib prefix="fmt" uri="http://java.sun.com/jstl/fmt" %>
<%@ page import="org.wso2.carbon.event.execution.manager.stub.ExecutionManagerAdminServiceStub" %>
<%@ page import="org.wso2.carbon.event.execution.manager.ui.ExecutionManagerUIUtils" %>
<%@ page import="org.wso2.carbon.event.execution.manager.admin.dto.configuration.xsd.ScenarioConfigurationDTO" %>
<%@ page import="org.wso2.carbon.event.execution.manager.admin.dto.configuration.xsd.ParameterDTOE" %>
<%@ page import="org.wso2.carbon.event.execution.manager.admin.dto.configuration.xsd.StreamMappingDTO" %>
<%@ page import="org.wso2.carbon.event.execution.manager.admin.dto.configuration.xsd.AttributeMappingDTO" %>
<%@ page import="org.apache.axis2.AxisFault" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="org.wso2.carbon.event.stream.stub.EventStreamAdminServiceStub" %>
<%@ page import="org.wso2.carbon.event.execution.manager.ui.ExecutionManagerUIConstants" %>
<%@ page import="java.util.ArrayList" %>

<%--
  ~ Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  --%>

<fmt:bundle basename="org.wso2.carbon.event.execution.manager.ui.i18n.Resources">
    <%

        if (!"post".equalsIgnoreCase(request.getMethod())) {
            response.sendError(405);
            return;
        }

        System.out.println("manageUpdateConfig");

        String domainName = request.getParameter("domainName");
        String configuration = request.getParameter("configurationName");
        String saveType = request.getParameter("saveType");
        String description = request.getParameter("description");
        String parametersJson = request.getParameter("parameters");
        String templateType = request.getParameter("templateType");
        String valueSeparator = "::";

        ParameterDTOE[] parameters;

        ExecutionManagerAdminServiceStub proxy = ExecutionManagerUIUtils.getExecutionManagerAdminService(config, session);
        try {
            if (saveType.equals("delete")) {
                proxy.deleteConfiguration(domainName, configuration);
            } else {

                ScenarioConfigurationDTO scenarioConfigurationDTO = new ScenarioConfigurationDTO();

                scenarioConfigurationDTO.setName(configuration);
                scenarioConfigurationDTO.setDomain(domainName);
                scenarioConfigurationDTO.setDescription(description);
                scenarioConfigurationDTO.setScenario(templateType);

                if (parametersJson.length() < 1) {
                    parameters = new ParameterDTOE[0];

                } else {
                    String[] parameterStrings = parametersJson.split(",");
                    parameters = new ParameterDTOE[parameterStrings.length];
                    int index = 0;

                    for (String parameterString : parameterStrings) {
                        ParameterDTOE parameterDTO = new ParameterDTOE();
                        parameterDTO.setName(parameterString.split(valueSeparator)[0]);
                        parameterDTO.setValue(parameterString.split(valueSeparator)[1]);
                        parameters[index] = parameterDTO;
                        index++;
                    }
                }

                scenarioConfigurationDTO.setParameterDTOs(parameters);

                //checks the "proxy.saveConfiguration(scenarioConfigurationDTO)" return value for not null and build stream mapping div
                if (proxy.saveConfiguration(scenarioConfigurationDTO) != null) {
                    String toStreamNameID = "";
                    String fromStreamNameID = "";
                    StreamMappingDTO[] streamMappingDTOs = null;

                    //toStreamIDArray.length defines the number of stream mappings per configuration
                    String toStreamIDArray[] = proxy.saveConfiguration(scenarioConfigurationDTO);
                    EventStreamAdminServiceStub eventStreamAdminServiceStub = ExecutionManagerUIUtils.getEventStreamAdminService(config,
                            session, request);
                    String[] fromStreamIds = eventStreamAdminServiceStub.getStreamNames();

                    //if update then set isExistingConfig to true
                    System.out.println("session " + ((StreamMappingDTO[]) session.getAttribute("streamMappingDTOs")));
                    if (((StreamMappingDTO[]) session.getAttribute("streamMappingDTOs")) != null) {
                        streamMappingDTOs = (StreamMappingDTO[]) session.getAttribute("streamMappingDTOs");
                    } else {
                        response.sendError(500);
                        return;
                    }
    %>
    <div class="container col-md-12 marg-top-20" id="streamMappingInnerDivID">
        <%
            for (int i = 0; i < toStreamIDArray.length; i++) {
                toStreamNameID = streamMappingDTOs[i].getToStream();
                fromStreamNameID = streamMappingDTOs[i].getFromStream();
                AttributeMappingDTO[] attributeMappingDTOs = streamMappingDTOs[i].getAttributeMappingDTOs();
        %>
        <div class="container col-md-12 marg-top-20" id="streamMappingConfigurationID_<%=i%>">

            <h4><fmt:message key='template.stream.header.text'/></h4>

            <label class="input-label col-md-5"><fmt:message key='template.label.to.stream.name'/></label>

            <div class="input-control input-full-width col-md-7 text">
                <input type="text" id="toStreamID_<%=i%>"
                       value="<%=toStreamNameID%>" readonly="true"/>
            </div>

            <label class="input-label col-md-5"><fmt:message key='template.label.from.stream.name'/></label>

            <div class="input-control input-full-width col-md-7 text">
                <select id="fromStreamID_<%=i%>" onchange="loadMappingFromStreamAttributes(<%=i%>)">
                    <option selected><%=fromStreamNameID%>
                    </option>
                    <%
                        if (fromStreamIds != null) {
                            Arrays.sort(fromStreamIds);
                            for (String aStreamId : fromStreamIds) {
                                fromStreamNameID = aStreamId;
                    %>
                    <option id="fromStreamOptionID"><%=fromStreamNameID%>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </div>

                <%-- add attribute mapping --%>
                <%--todo: modify to match the attribute type and load attribute list--%>
            <div id="outerDiv_<%=i%>">

                <%
                    ArrayList<AttributeMappingDTO> metaAttributeMappingDTOList = new ArrayList<AttributeMappingDTO>();
                    ArrayList<AttributeMappingDTO> correlationAttributeMappingDTOList = new ArrayList<AttributeMappingDTO>();
                    ArrayList<AttributeMappingDTO> payloadAttributeMappingDTOList = new ArrayList<AttributeMappingDTO>();

                    for (AttributeMappingDTO attributeMappingDTO : attributeMappingDTOs) {
                        if (attributeMappingDTO.getToAttribute().contains("meta_")) {
                            //set meta data
                            metaAttributeMappingDTOList.add(attributeMappingDTO);
                        } else if (attributeMappingDTO.getToAttribute().contains("correlation_")) {
                            //set correlation data
                            correlationAttributeMappingDTOList.add(attributeMappingDTO);
                        } else {
                            //set payload data
                            payloadAttributeMappingDTOList.add(attributeMappingDTO);
                        }
                    }%>

                <h4><fmt:message
                        key='template.stream.attribute.mapping.header.text'/></h4>
                <table style="width:100%" id="addEventDataTable_<%=i%>">
                    <tbody>

                        <%--get meta data--%>
                    <tr>
                        <td colspan="6">
                            <h6><fmt:message key="meta.attribute.mapping"/></h6>
                        </td>
                    </tr>
                    <%
                        int metaCounter = 0;
                        if (!metaAttributeMappingDTOList.isEmpty()) {
                            for (AttributeMappingDTO metaAttributeMappingDTO : metaAttributeMappingDTOList) {
                    %>
                    <tr id="metaMappingRow_<%=metaCounter%>">
                        <td>Mapped From :
                        </td>
                        <td>
                            <select id="metaEventMappingValue_<%=i%><%=metaCounter%>">
                                <option selected><%=metaAttributeMappingDTO.getFromAttribute()%>
                                </option>
                            </select>
                        </td>
                        <td>Mapped To :
                        </td>
                        <td>
                            <input type="text" id="metaEventMappedValue_<%=i%><%=metaCounter%>"
                                   value="<%=ExecutionManagerUIConstants.PROPERTY_META_PREFIX + metaAttributeMappingDTO.getToAttribute()%>"
                                   readonly="true"/>
                        </td>
                        <td>Attribute Type :
                        </td>
                        <td>
                            <input type="text" id="metaEventType_<%=i%><%=metaCounter%>"
                                   value="<%=metaAttributeMappingDTO.getAttributeType()%>" readonly="true"/>
                        </td>
                    </tr>
                    <%
                            metaCounter++;
                        }
                    } else {
                    %>
                    <tr>
                        <td colspan="6">
                            <div id="noInputMetaEventData">
                                No Meta Attributes to define
                            </div>
                        </td>
                    </tr>
                    <%
                        }
                    %>

                        <%--get correlation data--%>
                    <tr>
                        <td colspan="6">
                            <h6><fmt:message key="correlation.attribute.mapping"/></h6>
                        </td>
                    </tr>
                    <%
                        int correlationCounter = 0;
                        if (!correlationAttributeMappingDTOList.isEmpty()) {
                            for (AttributeMappingDTO correlationAttributeMappingDTO : correlationAttributeMappingDTOList) {
                    %>
                    <tr id="correlationMappingRow_<%=correlationCounter%>">
                        <td>Mapped From :
                        </td>
                        <td>
                            <select id="correlationEventMappingValue_<%=i%><%=correlationCounter%>">
                                <option selected><%=correlationAttributeMappingDTO.getFromAttribute()%>
                                </option>
                            </select>
                        </td>
                        <td>Mapped To :
                        </td>
                        <td>
                            <input type="text" id="correlationEventMappedValue_<%=i%><%=correlationCounter%>"
                                   value="<%=ExecutionManagerUIConstants.PROPERTY_CORRELATION_PREFIX + correlationAttributeMappingDTO.getToAttribute()%>"
                                   readonly="true"/>
                        </td>
                        <td>Attribute Type :
                        </td>
                        <td>
                            <input type="text" id="correlationEventType_<%=i%><%=correlationCounter%>"
                                   value="<%=correlationAttributeMappingDTO.getAttributeType()%>" readonly="true"/>
                        </td>
                    </tr>
                    <%
                            correlationCounter++;
                        }
                    } else {
                    %>
                    <tr>
                        <td colspan="6">
                            <div id="noInputCorrelationEventData">
                                No Correlation Attributes to define
                            </div>
                        </td>
                    </tr>
                    <%
                        }
                    %>

                        <%--get payload data--%>
                    <tr>
                        <td colspan="6">
                            <h6><fmt:message key="payload.attribute.mapping"/></h6>
                        </td>
                    </tr>
                    <%
                        int payloadCounter = 0;
                        if (!payloadAttributeMappingDTOList.isEmpty()) {
                            for (AttributeMappingDTO payloadAttributeMappingDTO : payloadAttributeMappingDTOList) {
                    %>
                    <tr id="payloadMappingRow_<%=payloadCounter%>">
                        <td>Mapped From :
                        </td>
                        <td>
                            <select id="payloadEventMappingValue_<%=i%><%=payloadCounter%>">
                                <option selected><%=payloadAttributeMappingDTO.getFromAttribute()%>
                                </option>
                            </select>
                        </td>
                        <td>Mapped To :
                        </td>
                        <td>
                            <input type="text" id="payloadEventMappedValue_<%=i%><%=payloadCounter%>"
                                   value="<%=payloadAttributeMappingDTO.getToAttribute()%>"
                                   readonly="true"/>
                        </td>
                        <td>Attribute Type :
                        </td>
                        <td>
                            <input type="text" id="payloadEventType_<%=i%><%=payloadCounter%>"
                                   value="<%=payloadAttributeMappingDTO.getAttributeType()%>" readonly="true"/>
                        </td>
                    </tr>
                    <%
                            payloadCounter++;
                        }
                    } else {
                    %>
                    <tr>
                        <td colspan="6">
                            <div id="noInputPayloadEventData">
                                No Payload Attributes to define
                            </div>
                        </td>
                    </tr>
                    <%
                        }
                    %>
                    </tbody>
                    <div style="display: none">
                        <input type="text" id="metaRows"
                               value="<%=metaCounter%>"/>
                        <input type="text" id="correlationRows"
                               value="<%=correlationCounter%>"/>
                        <input type="text" id="payloadRows"
                               value="<%=payloadCounter%>"/>
                    </div>
                </table>
            </div>
        </div>
        <%
            }
        %>

        <br class="c-both"/>
        <hr class="wr-separate"/>

        <div class="action-container">
            <button type="button"
                    class="btn btn-default btn-add col-md-2 col-xs-12 pull-right marg-right-15"
                    onclick="saveStreamConfiguration('<%=toStreamIDArray.length%>','<%=domainName%>','<%=configuration%>')">
                <fmt:message key='template.add.stream.button.text'/>
            </button>
        </div>
    </div>
    <%
                } else {
                    proxy.saveConfiguration(scenarioConfigurationDTO);
                }
            }
        } catch (AxisFault e) {
            response.sendError(500);
        }
    %>
</fmt:bundle>