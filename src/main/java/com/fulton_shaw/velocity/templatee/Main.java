package com.fulton_shaw.velocity.templatee;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.Velocity;
import org.apache.velocity.context.Context;
import org.apache.velocity.runtime.RuntimeConstants;
import org.apache.velocity.tools.ToolContext;
import org.apache.velocity.tools.ToolManager;

import java.io.*;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.util.Calendar;
import java.util.List;

/**
 * @author xiaohuadong
 * @date 2019/06/06
 */
public class Main {
    private static void initContext(String path, Context context) {
        context.put("template", path);
        context.put("sysprop", System.getProperties());
        context.put("System", System.class);
        context.put("Math", Math.class);
        context.put("Paths", Paths.class);
        context.put("PathUtils", PathUtils.class);
        context.put("StringUtils", StringUtils.class);
        context.put("IOUtils", IOUtils.class);
        context.put("PojoUtils", PojoUtils.class);
        context.put("DataUtils", DataUtils.class);
        context.put("ParamUtils", ParamUtils.class);
        Calendar calendar = Calendar.getInstance();
        context.put("NOW_DATE", calendar.getTime());
        context.put("NOW_YEAR", calendar.get(Calendar.YEAR));
        context.put("NOW_MONTH", calendar.get(Calendar.MONTH) + 1);
        context.put("NOW_DAY", calendar.get(Calendar.DAY_OF_MONTH));
        // override all
        String importList = System.getProperty("import.class.list");
        List<List<String>> lists = ParamUtils.parseList("\\s*,\\s*", ":", importList);
        for (List<String> list : lists) {
            String name = null;
            String className = null;
            if (list.size() == 1) {
                className = list.get(0);
                name = PojoUtils.getShortName(className);
            } else {
                if (list.size() != 2) {
                    throw new IllegalArgumentException("require [NAME:]CLASS format");
                }
                name = list.get(0);
                className = list.get(1);
            }
            if (StringUtils.isBlank(name)) {
                throw new IllegalArgumentException("name cannot be blank");
            }
            try {
                context.put(name, Class.forName(className));
            } catch (ClassNotFoundException e) {
                throw new RuntimeException(e);
            }
        }

    }

    public static final String HELP = "Instantiate velocity template files\n" +
            "Usage: velocity-templatee [help|template] [TEMPLATE_FILE|-] [key1=value1 key2=value2....]\n" +
            "if TEMPLATE_FILE is -, then it is read from stdin\n" +
            "The jvm options will be used to instantiate the Velocity engine,remarkable properties are:\n" +
            "    file.resource.loader.path = . \n" +
            "    input.encoding = UTF-8\n" +
            "    output.encoding = UTF-8\n" +
            "    import.class.list = NAME:fullPath,..." +
            "\n" +
            "Available context  arguments are shown as following:\n" +
            "    _PARAM          the runtime argument\n" +
            "    template        the template file used\n" +
            "    sysprop         the System.getProperties\n" +
            "    System          the System\n" +
            "    Math            the Math.class\n" +
            "    Paths           the Paths.class\n" +
            "    PathUtils       the PathUtils.class\n" +
            "    StringUtils     the StringUtils.class\n" +
            "    IOUtils         the IOUtils.class\n" +
            "    PojoUtils       the PojoUtils.class\n" +
            "    DataUtils       the DataUtils.class\n" +
            "    ParamUtils      the ParamUtils.class\n"+
            "    <Velocity Generic Tools>\n" +
            "    NOW_DATE        current Date object\n" +
            "    NOW_YEAR        current year\n" +
            "    NOW_MONTH       current month\n" +
            "    NOW_DAY         current day of month\n";

    public static void main(String[] args) throws FileNotFoundException {
        String command = args.length == 0 ? "help" : args[0];
        if ("help".equals(command)) {
            System.out.println(HELP);
            return;
        }

        if ("template".equals(command)) {
            Velocity.init(System.getProperties());

            String inputEnc = System.getProperty(RuntimeConstants.INPUT_ENCODING);
            if (inputEnc == null) {
                inputEnc = StandardCharsets.UTF_8.name();
            }
            String outputEnc = System.getProperty("output.encoding");
            if (outputEnc == null) {
                outputEnc = StandardCharsets.UTF_8.name();
            }


            Reader templateReader = null;

            String path = (args.length < 2 ? "-" : args[1]);
            if ("-".equals(path)) {
                templateReader = new InputStreamReader(System.in, Charset.forName(inputEnc));
            } else {
                templateReader = new InputStreamReader(new FileInputStream(new File(PathUtils.correctPath(path))), Charset.forName(inputEnc));
            }

            ToolManager toolManager = new ToolManager(false, true);
            // locate the tools by hand(else org.apache.velocity.tools will be used as property)
            toolManager.configure("org/apache/velocity/tools/generic/tools.xml");
            ToolContext context = toolManager.createContext();
            context.put("_PARAM", ParamUtils.recoveryShellParam(args));
            initContext(path, context);
            if (args.length > 2) {
                for (int i = 2; i < args.length; i++) {
                    int idx = args[i].indexOf('=');
                    String key = idx != -1 ? args[i].substring(0, idx) : args[i];
                    String value = idx != -1 && (idx + 1) < args[i].length() ? args[i].substring(idx + 1) : "";
                    context.put(key, value);
                }
            }
            OutputStreamWriter writer = new OutputStreamWriter(System.out, Charset.forName(outputEnc));


            Velocity.evaluate(context, writer, path, templateReader);

            IOUtils.closeQuietly(templateReader);
            IOUtils.closeQuietly(writer);

            // returns good
            System.exit(0);
        } else {
            System.err.println("Unknown command '" + command + "'");
            System.exit(1);
        }
    }

}
